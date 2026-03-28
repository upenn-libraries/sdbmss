require 'net/http'
require 'open3'
require 'shellwords'
require 'socket'
require 'tmpdir'
require 'uri'

module SDBMSS
  # Orchestrates local development environment setup and lifecycle management via
  # Docker Compose. Handles building custom images, loading data archives, running
  # database migrations, and configuring Jena Fuseki.
  #
  # Most public methods call +load_docker_environment!+ first to populate @env from
  # +.env+, so that file must exist before any command is run.
  #
  # Required +.env+ keys: +INTERFACE_REPO+, +JENA_REPO+ (git URLs used to build
  # the interface and Jena custom images).
  #
  # Initially generated with assistance from GPT-5.2-Codex (OpenAI).
  # Documentation, troubleshooting, and subsequent edits by Claude Sonnet 4.6 (Anthropic).
  class Tools

    class << self
      # Polls +host+ over HTTP until a 200 response is received or +timeout_seconds+ elapses.
      #
      # @param host [String] hostname (and optional port) to poll, e.g. "sdbmss.localhost"
      # @param timeout_seconds [Integer] how long to wait before giving up
      # @param interval_seconds [Integer] seconds to sleep between attempts
      # @param out [IO] output stream for error messages
      # @return [Boolean] true if the app responded 200 within the timeout, false otherwise
      def sdbm_available?(host, timeout_seconds: 180, interval_seconds: 2, out: $stdout)
        uri = URI.parse("http://#{host}")
        started_at = Time.now

        loop do
          begin
            response = Net::HTTP.start(uri.host, uri.port, open_timeout: 3, read_timeout: 3) do |http|
              http.get(uri.request_uri.empty? ? '/' : uri.request_uri)
            end
            return true if response.code.to_i == 200
          rescue StandardError
            # retry until timeout
          end

          break if (Time.now - started_at) >= timeout_seconds

          sleep interval_seconds
        end

        out.puts("[tools] #{timestamp} ERROR app did not return HTTP 200 at #{uri} within #{timeout_seconds}s")
        false
      end

      # @return [String] current UTC time in ISO-8601 format, e.g. "2024-01-01T12:00:00Z"
      def timestamp
        Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
      end

      # Returns true for common truthy string values (1, true, yes, y, on).
      #
      # @param value [Object] value to test
      # @return [Boolean]
      def truthy?(value)
        %w[1 true yes y on].include?(value.to_s.strip.downcase)
      end
    end

    # @param env [Hash] environment variables; defaults to the process ENV
    # @param out [IO] output stream for log messages
    def initialize(env: ENV, out: $stdout)
      @env = env
      @out = out
    end

    # Builds any missing custom images, starts the Compose stack, waits for the app
    # to become reachable, and prints a diagnostic if the /etc/hosts entry is missing.
    # Skips data-file verification unless +TOOLS_REQUIRE_DATA=1+ is set.
    #
    # @param force_rebuild [Boolean] rebuild custom images even if they already exist
    def start(force_rebuild: false)
      timed('start') do
        load_docker_environment!
        verify_data_files! if self.class.truthy?(env('TOOLS_REQUIRE_DATA', nil))
        ensure_custom_images!(force: force_rebuild)
        run_compose!(%w[up -d])
        wait_for_sdbm_availability!
        diagnose_host_mapping
      end
    end

    # Stops all Compose services without removing volumes.
    def stop
      timed('stop') do
        load_docker_environment!
        run_compose!(%w[stop])
      end
    end

    # Removes all Compose services and their volumes (+docker compose down -v+).
    # Pass +scope: :all+ to also remove custom images.
    #
    # @param scope [:containers, :all] what to remove;
    #   +:containers+ removes services and volumes only (default);
    #   +:all+ also removes custom images
    def clean(scope: :containers)
      timed('clean') do
        load_docker_environment!
        run_compose!(%w[down -v])
        remove_custom_images! if scope == :all
      end
    end

    # Removes and rebuilds all custom images without starting the Compose stack.
    # Useful when upstream image source repos have changed.
    def rebuild
      timed('rebuild') do
        load_docker_environment!
        remove_custom_images!
        ensure_custom_images!(force: true)
      end
    end

    # Full local setup flow: verifies data files, waits for the app, then runs
    # +setup_assets+, +setup_db+, adds test users, reindexes Solr, and runs +setup_jena+.
    def setup
      timed('setup') do
        load_docker_environment!
        verify_data_files!
        wait_for_sdbm_availability!
        diagnose_host_mapping

        setup_assets
        setup_db
        run_in_app!('bundle exec rake sdbmss:add_update_test_users')
        run_in_app!('bundle exec rake sunspot:reindex >/dev/null 2>&1')
        setup_jena
      end
    end

    # Extracts the static assets archive (+sdbm_data.tgz+) and copies the +docs+,
    # +tooltips+, and +uploads+ directories into the running app container.
    # Rewrites hard-coded hostnames in +home_text.html+ to match +SDBMSS_APP_HOST+.
    def setup_assets
      load_docker_environment!
      verify_data_files!

      archive = data_archive_path
      Dir.mktmpdir('sdbm_data_extract') do |tmpdir|
        log('Extracting static assets archive')
        run_command!(['tar', 'xf', archive, '-C', tmpdir], chdir: rails_root)

        extracted_dir = File.join(tmpdir, 'sdbm_data')
        raise "Expected extracted directory #{extracted_dir}" unless Dir.exist?(extracted_dir)

        rewrite_home_text!(File.join(extracted_dir, 'uploads', 'home_text.html'))

        %w[docs tooltips uploads].each do |dirname|
          src = File.join(extracted_dir, dirname)
          next unless Dir.exist?(src)

          run_command!(['docker', 'cp', src, "#{app_container_id}:/home/app/public/static/"])
          log("Copied #{dirname} into app container")
        end
      end
    end

    # Copies the SQL archive (+sdbm.sql.gz+) into the mysql container, decompresses
    # and pipes it into MySQL, removes the archive, then runs +db:migrate+.
    def setup_db
      load_docker_environment!
      verify_data_files!

      sql_archive = sql_archive_path
      mysql_id = mysql_container_id

      log('Copying SQL archive to mysql container')
      run_command!(['docker', 'cp', sql_archive, "#{mysql_id}:/tmp/sdbm.sql.gz"])

      log('Loading SQL archive into mysql')
      mysql_user     = Shellwords.shellescape(env('MYSQL_USER'))
      mysql_password = Shellwords.shellescape(env('MYSQL_PASSWORD'))
      mysql_database = Shellwords.shellescape(env('MYSQL_DATABASE'))
      run_command!(%W[docker exec -i --workdir /tmp #{mysql_id} sh -c] + ["gunzip -c /tmp/sdbm.sql.gz | mysql -u #{mysql_user} --password=#{mysql_password} #{mysql_database}"])

      log('Removing mysql SQL archive')
      run_command!(%W[docker exec #{mysql_id} rm -f /tmp/sdbm.sql.gz])

      run_in_app!('bundle exec rake db:migrate')
    end

    # Generates RDF test data via +sparql:test+, loads it into Jena Fuseki using
    # +tdbloader+, installs the dataset configuration TTL, and restarts the jena service.
    def setup_jena
      load_docker_environment!

      run_in_app!('bundle exec rake sparql:test')

      ttl_path = File.join(rails_root, 'dev', 'test.ttl')
      run_command!(['docker', 'cp', "#{app_container_id}:/home/app/test.ttl", ttl_path])

      run_compose!(%w[stop jena])

      image = [env('JENA_IMAGE_NAME', nil), env('JENA_IMAGE_TAG', nil)].compact.join(':')
      image = 'sdbmss-jena:latest' if image.empty? || image == ':'

      run_command!([
        'docker', 'run', '--rm', '--entrypoint', '/jena-fuseki/tdbloader',
        '--mount', "source=#{compose_volume_prefix}rdf_data,target=/fuseki",
        '-v', "#{File.join(rails_root, 'dev')}:/data:ro", image,
        '--loc=/fuseki/databases/sdbm', '/data/test.ttl'
      ])

      run_command!([
        'docker', 'run', '--rm',
        '--mount', "source=#{compose_volume_prefix}rdf_data,target=/fuseki",
        '-v', "#{File.join(rails_root, 'dev', 'sdbm.ttl')}:/tmp/sdbm.ttl:ro",
        'alpine', 'sh', '-c',
        'mkdir -p /fuseki/configuration && cp /tmp/sdbm.ttl /fuseki/configuration/sdbm.ttl && chmod 0644 /fuseki/configuration/sdbm.ttl'
      ])

      run_compose!(%w[start jena])
    end

    # Builds a Docker image from a remote git URL. Skips the build if the image
    # already exists unless +force: true+ is passed.
    #
    # @param url [String] git URL used as the Docker build context
    # @param image_name [String] name for the resulting image
    # @param tag [String] tag for the resulting image
    # @param force [Boolean] rebuild even if the image already exists
    def build_image(url:, image_name:, tag:, force: false)
      load_docker_environment!
      image_ref = "#{image_name}:#{tag}"
      if image_exists?(image_ref) && !force
        log("Image #{image_ref} already exists; skipping build")
        return
      end

      log("Building image #{image_ref} from #{url}")
      run_command!(['docker', 'build', '--pull', '-t', image_ref, url])
    end

    # Removes all custom images (interface, jena, and app) that currently exist locally.
    # Silently skips images that are not present.
    def remove_custom_images!
      custom_images.each do |_url, image_name, tag|
        ref = "#{image_name}:#{tag}"
        if image_exists?(ref)
          log("Removing image #{ref}")
          run_command!(['docker', 'image', 'rm', ref])
        else
          log("Image #{ref} not present; skipping removal")
        end
      end

      app_ref = "#{env('APP_IMAGE_NAME', 'sdbmss')}:#{env('APP_IMAGE_TAG', 'development')}"
      if image_exists?(app_ref)
        log("Removing image #{app_ref}")
        run_command!(['docker', 'image', 'rm', app_ref])
      else
        log("Image #{app_ref} not present; skipping removal")
      end
    end

    # Builds all custom images if they do not already exist.
    #
    # @param force [Boolean] rebuild all images even if they already exist
    def ensure_custom_images!(force: false)
      custom_images.each do |url, image, tag|
        build_image(url: url, image_name: image, tag: tag, force: force)
      end
    end

    # Checks whether +SDBMSS_APP_HOST+ is resolvable and reachable on port 80.
    # Logs a warning with the required /etc/hosts entry if the hostname is missing,
    # and logs a connectivity warning if the TCP connection fails.
    def diagnose_host_mapping
      host = app_host
      return if host.nil? || host.empty?

      hosts_has_mapping = hosts_mapping_present?(host)
      unless hosts_has_mapping
        log("WARNING /etc/hosts does not include '#{host}'")
        @out.puts("[tools] #{self.class.timestamp} Add this line to /etc/hosts:\n127.0.0.1 #{host}")
      end

      begin
        Socket.getaddrinfo(host, 80)
        TCPSocket.new(host, 80).close
      rescue Errno::EHOSTUNREACH, Errno::ENETUNREACH, Errno::EHOSTDOWN, Errno::ECONNREFUSED, SocketError => e
        @out.puts("[tools] #{self.class.timestamp} WARNING Host diagnostics for #{host} detected connectivity issue: #{e.class}: #{e.message}")
        @out.puts("[tools] #{self.class.timestamp} Verify /etc/hosts contains '127.0.0.1 #{host}' and Docker is forwarding port 80.")
      end
    end

    private

    # Polls until the app returns HTTP 200, raising if it does not within the timeout.
    def wait_for_sdbm_availability!
      host = app_host
      raise 'SDBMSS_APP_HOST is required in .env' if host.nil? || host.empty?

      log("Waiting for app availability at http://#{host}")
      return if self.class.sdbm_available?(host, out: @out)

      raise "Application is not reachable at http://#{host}"
    end

    # Raises if either the data archive or SQL archive file does not exist on disk.
    def verify_data_files!
      [data_archive_path, sql_archive_path].each do |path|
        next if File.exist?(path)

        raise "Required file not found: #{path}. Set SDBM_DATA_ARCHIVE / SDBM_SQL_ARCHIVE or place data under rails_app/dev/data."
      end
    end

    # Replaces hard-coded production hostname in +home_text.html+ with +SDBMSS_APP_HOST+.
    #
    # @param file_path [String] path to the home_text.html file
    def rewrite_home_text!(file_path)
      return unless File.exist?(file_path)

      content = File.read(file_path)
      updated = content.gsub('sdbm.library.upenn.edu', app_host)
      File.write(file_path, updated)
    end

    # Delegates to +Hash#fetch+ on the environment. With no default, raises +KeyError+
    # if the key is absent; with a default, returns it instead.
    #
    # @param key [String] environment variable name
    # @param args [Array] optional single default value, forwarded to +fetch+
    # @return [String, nil]
    # @raises [KeyError] if the key is absent and no default is given
    def env(key, *args)
      @env.fetch(key, *args)
    end

    # @return [String, nil] value of +SDBMSS_APP_HOST+ from the environment
    def app_host
      env('SDBMSS_APP_HOST', nil)
    end

    # @return [String] Docker volume name prefix derived from +COMPOSE_PROJECT_NAME+
    def compose_volume_prefix
      "#{env('COMPOSE_PROJECT_NAME', 'rails_app')}_"
    end

    # @return [String] absolute path to the static assets archive
    def data_archive_path
      @data_archive_path ||= begin
                               path = env('SDBM_DATA_ARCHIVE', nil) || File.join(rails_root, 'dev', 'data', 'sdbm_data.tgz')
                               File.expand_path(path, rails_root)
                             end
    end

    # @return [String] absolute path to the SQL dump archive
    def sql_archive_path
      @sql_archive_path ||= begin
                              path = env('SDBM_SQL_ARCHIVE', nil) || File.join(rails_root, 'dev', 'data', 'sdbm.sql.gz')
                              File.expand_path(path, rails_root)
                            end
    end

    # @return [String] Docker container ID for the running +app+ service
    def app_container_id
      @app_container_id ||= capture_command!(compose_command + %w[ps -q app]).strip
    end

    # @return [String] Docker container ID for the running +mysql+ service
    def mysql_container_id
      @mysql_container_id ||= capture_command!(compose_command + %w[ps -q mysql]).strip
    end

    # Reads +.env+ and populates @env with any keys not already set.
    # Raises if the file does not exist.
    def load_docker_environment!
      env_file = File.join(rails_root, '.env')
      unless File.exist?(env_file)
        raise "Missing #{env_file}. Copy rails_app/docker-environment-sample to rails_app/.env and edit values."
      end

      File.readlines(env_file).each do |line|
        next if line.strip.empty? || line.strip.start_with?('#')

        key, value = line.split('=', 2)
        next if key.nil? || value.nil?

        @env[key.strip] ||= value.strip
      end
    end

    # Returns remote-built custom images as +[url, image_name, tag]+ triples.
    # URLs and names/tags are read from the environment so they can be overridden via +.env+.
    # Raises +KeyError+ if +INTERFACE_REPO+ or +JENA_REPO+ is not set.
    #
    # @return [Array<Array<String>>]
    def custom_images
      [
        [env('INTERFACE_REPO'), env('INTERFACE_IMAGE_NAME', 'sdbmss-interface'), env('INTERFACE_IMAGE_TAG', 'latest')],
        [env('JENA_REPO'),      env('JENA_IMAGE_NAME',      'sdbmss-jena'),      env('JENA_IMAGE_TAG',      'latest')]
      ]
    end

    # @return [Array<String>] base +docker compose+ command
    def compose_command
      ['docker', 'compose']
    end

    # Runs a +docker compose+ subcommand, streaming output to @out.
    #
    # @param args [Array<String>] arguments to append to the base compose command
    def run_compose!(args)
      log("docker compose #{args.join(' ')}")
      run_command!(compose_command + args, chdir: rails_root)
    end

    # Runs a command inside the +app+ container via +docker compose exec+.
    # Uses +-T+ to disable pseudo-TTY allocation (safe for non-interactive use).
    #
    # @param command [String] shell command to execute inside the container
    def run_in_app!(command)
      log("app exec: #{command}")
      run_command!(compose_command + ['exec', '-T', 'app', 'bash', '-lc', command], chdir: rails_root)
    end

    # @param image_ref [String] image reference, e.g. "sdbmss-interface:latest"
    # @return [Boolean] true if the image exists locally
    def image_exists?(image_ref)
      system('docker', 'image', 'inspect', image_ref, out: File::NULL, err: File::NULL)
    end

    # @param host [String] hostname to look up
    # @return [Boolean] true if /etc/hosts contains an entry for the host
    def hosts_mapping_present?(host)
      File.readlines('/etc/hosts').any? do |line|
        clean = line.sub(/#.*/, '').strip
        next false if clean.empty?

        clean.split(/\s+/)[1..-1].to_a.include?(host)
      end
    rescue Errno::EACCES
      false
    end

    # Runs a command and captures its stdout. Raises if the command exits non-zero.
    # Uses +capture2+ (stdout only) so that stderr noise (e.g. Docker Compose warnings)
    # does not contaminate the returned output.
    #
    # @param cmd [Array<String>] command and arguments
    # @return [String] captured stdout
    def capture_command!(cmd)
      log("Running: #{Shellwords.join(cmd)}")
      output, status = Open3.capture2(*cmd, chdir: rails_root)
      unless status.success?
        raise "Command failed (#{status.exitstatus}): #{Shellwords.join(cmd)}\n#{output}"
      end

      output
    end

    # Runs a command, streaming combined stdout/stderr to @out. Raises if the command
    # exits non-zero.
    #
    # @param cmd [Array<String>] command and arguments
    # @param chdir [String, nil] working directory; defaults to +rails_root+
    def run_command!(cmd, chdir: nil)
      chdir ||= rails_root
      log("Running: #{Shellwords.join(cmd)}")
      Open3.popen2e(*cmd, chdir: chdir) do |_stdin, outerr, wait_thr|
        outerr.each { |line| @out.write(line) }
        status = wait_thr.value
        unless status.success?
          raise "Command failed (#{status.exitstatus}): #{Shellwords.join(cmd)}"
        end
      end
    end

    # Logs a start message, yields to the block, then logs completion with elapsed time.
    #
    # @param label [String] human-readable name for the operation, used in log output
    def timed(label)
      start = Time.now
      log("#{label} starting")
      yield
      elapsed = (Time.now - start).round(1)
      log("#{label} completed in #{elapsed}s")
    end

    # Writes a timestamped log line to @out.
    #
    # @param message [String]
    def log(message)
      @out.puts("[tools] #{self.class.timestamp} #{message}")
    end

    # @return [String] absolute path to the Rails application root
    def rails_root
      @rails_root ||= File.expand_path('../..', __dir__)
    end
  end
end
