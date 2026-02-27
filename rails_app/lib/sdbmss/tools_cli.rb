require 'optparse'
require 'sdbmss/tools'

module SDBMSS
  class ToolsCLI
    Command = Struct.new(:name, :options)

    def initialize(argv: ARGV, out: $stdout, err: $stderr, env: ENV)
      @argv = argv.dup
      @out = out
      @err = err
      @env = env
    end

    def run
      command = parse!
      tools = SDBMSS::Tools.new(env: @env, out: @out)

      if command.name == 'help'
        @out.puts(help_text)
        return 0
      end

      case command.name
      when 'start'
        tools.start(force_rebuild: command.options[:force])
      when 'stop'
        tools.stop
      when 'clean'
        tools.clean
      when 'setup'
        tools.setup
      when 'setup-assets'
        tools.setup_assets
      when 'setup-db'
        tools.setup_db
      when 'setup-jena'
        tools.setup_jena
      when 'build-image'
        tools.build_image(
          url: command.options.fetch(:url),
          image_name: command.options.fetch(:image_name),
          tag: command.options.fetch(:tag),
          force: command.options[:force]
        )
      else
        raise ArgumentError, "Unsupported command: #{command.name}"
      end

      0
    rescue OptionParser::ParseError, ArgumentError => e
      @err.puts("ERROR: #{e.message}")
      @err.puts(help_text)
      1
    rescue StandardError => e
      @err.puts("ERROR: #{e.class}: #{e.message}")
      @err.puts(e.backtrace.join("\n")) if e.backtrace
      1
    end

    def parse!
      command_name = @argv.shift
      raise ArgumentError, 'Please provide a command.' if command_name.nil? || command_name.strip.empty?

      return Command.new('help', {}) if %w[help -h --help].include?(command_name)

      case command_name
      when 'start'
        parse_start
      when 'stop', 'clean', 'setup', 'setup-assets', 'setup-db', 'setup-jena'
        parse_simple(command_name)
      when 'build-image'
        parse_build_image
      else
        raise ArgumentError, "Unknown command '#{command_name}'."
      end
    end

    def help_text
      <<~HELP
        Usage: ruby bin/tools <command> [options]

        Commands:
          start [--force]                     Start services (docker compose up -d)
          stop                                Stop services (docker compose stop)
          clean                               Remove services and volumes (docker compose down -v)
          setup                               Run full LOCAL setup flow
          setup-assets                        Run assets setup only
          setup-db                            Run database setup only
          setup-jena                          Run Jena setup only
          build-image --url URL --image-name NAME [--tag TAG] [--force]
                                              Build a custom image from a git URL

        Examples:
          ruby bin/tools start
          ruby bin/tools start --force
          ruby bin/tools setup
          ruby bin/tools build-image --url https://github.com/upenn-libraries/sdbm-interface.git --image-name sdbmss-interface --tag latest
      HELP
    end

    private

    def parse_simple(command_name)
      parser = OptionParser.new
      parser.on('-h', '--help', 'Show help') do
        raise ArgumentError, help_text
      end
      parser.parse!(@argv)
      raise ArgumentError, "Unexpected arguments: #{@argv.join(' ')}" unless @argv.empty?

      Command.new(command_name, {})
    end

    def parse_start
      options = { force: false }
      parser = OptionParser.new
      parser.on('--force', 'Force rebuild custom images before start') do
        options[:force] = true
      end
      parser.on('-h', '--help', 'Show help') do
        raise ArgumentError, help_text
      end
      parser.parse!(@argv)
      raise ArgumentError, "Unexpected arguments: #{@argv.join(' ')}" unless @argv.empty?

      Command.new('start', options)
    end

    def parse_build_image
      options = {
        url: nil,
        image_name: nil,
        tag: 'latest',
        force: false
      }

      parser = OptionParser.new
      parser.on('--url URL', 'Git URL for the image build context') { |v| options[:url] = v }
      parser.on('--image-name NAME', 'Image name to build') { |v| options[:image_name] = v }
      parser.on('--tag TAG', 'Image tag (default: latest)') { |v| options[:tag] = v }
      parser.on('--force', 'Force rebuild even if image exists') { options[:force] = true }
      parser.on('-h', '--help', 'Show help') do
        raise ArgumentError, help_text
      end
      parser.parse!(@argv)

      raise ArgumentError, '--url is required for build-image' if options[:url].to_s.strip.empty?
      raise ArgumentError, '--image-name is required for build-image' if options[:image_name].to_s.strip.empty?
      raise ArgumentError, "Unexpected arguments: #{@argv.join(' ')}" unless @argv.empty?

      Command.new('build-image', options)
    end
  end
end
