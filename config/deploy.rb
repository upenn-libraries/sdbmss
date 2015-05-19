
set :application, 'sdbmss'
set :repo_url, 'git@github.com:upenn-libraries/sdbmss.git'
set :branch, 'master'

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/var/www/sdbmss/'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, fetch(:linked_files, []).push('config/database.yml')

# Default value for linked_dirs is []
# set :linked_dirs, fetch(:linked_dirs, []).push('bin', 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do

  desc "Update solr config in the shared path"
  task :solr_update do
    on roles(:all) do

      current_solr = File.join current_path, "solr"
      shared_solr = File.join shared_path, "solr"

      # Capistrano has a linked_dirs variable that it uses to
      # automatically create symlinks from current_path to
      # shared_path. We should probably use that, but we need to
      # figure out where, in the flow, to overlay the solr files into
      # shared BEFORE the symlinking happens.

      # update our shared solr path, which remains constant between
      # releases
      execute :mkdir, "-p #{shared_solr}"
      execute :cp, "-r #{current_solr} #{shared_path}"

      execute :rm, "-rf #{current_solr}"
      execute :ln, "-s #{shared_solr} #{current_solr}"
    end
  end

  desc "Stop solr"
  task :solr_stop do
    on roles(:all) do
      # always exit 0 (if solr isn't running, ignore error return code)
      execute "if [[ -d #{current_path} ]]; then cd #{current_path} && bundle exec rake sunspot:solr:stop; fi; exit 0"
    end
  end

  desc "Start solr"
  task :solr_start do
    on roles(:all) do
      within current_path do
        execute :bundle, "exec rake sunspot:solr:start"
      end
    end
  end

  desc "Stop unicorn"
  task :unicorn_stop do
    on roles(:all) do
      pid_file = File.join(current_path, "tmp", "pids", "unicorn.pid")
      if test("[ -f #{pid_file} ]")
        within current_path do
          begin
            execute :kill, "`cat #{pid_file}`"
          rescue Exception => e
            # this can happen if last unicorn start failed and left a stale pid file.
            execute :echo, "Ignoring error when trying to kill unicorn"
          end
        end
      end
    end
  end

  desc "Make pids directory"
  task :mkdir_pids do
    on roles(:all) do
      within current_path do
        pids_dir = File.join(shared_path, "pids")
        execute :mkdir, "-p #{pids_dir}"
      end
    end
  end

  desc "Start unicorn"
  task :unicorn_start do
    on roles(:all) do
      within current_path do
        pids_dir = File.join(current_path, "tmp", "pids")
        execute :mkdir, "-p #{pids_dir}"
        execute :bundle, "exec unicorn -c config/unicorn.rb -D"
      end
    end
  end

  desc "Upload the .SQL file to remote host, and recreate the database"
  task :recreate_database, :database_file do |tasks, args|
    if args[:database_file]
      on roles(:all) do
        set :confirm, ask("whether you REALLY want to do this", "n")
        if fetch(:confirm) == 'y'

          # monkey patch to supress upload status, which spews a lot
          # of output and is REALLY annoying
          class SSHKit::Backend::Netssh
            def transfer_summarizer(action)
              nil
            end
          end

          puts "Uploading, please wait..."
          upload!(args[:database_file], shared_path)

          remote_path = File.join shared_path, File.basename(args[:database_file])
          execute "cat #{remote_path} | mysql -u root sdbm"

          within current_path do
            execute :bundle, "exec rake sunspot:reindex"
          end
        else
          puts "Aborting."
        end
      end
    else
      puts "Error: specify a database file to use, as a task argument"
    end
  end

  def god_is_running
    !capture("cd #{current_path}; bundle exec god status >/dev/null 2>/dev/null || echo 'not running'").start_with?('not running')
  end

  desc "Start god"
  task :god_start do
    on roles(:all) do
      within current_path do
        execute :bundle, "exec god -c sdbmss.god"
      end
    end
  end

  desc "Stop god"
  task :god_stop do
    on roles(:all) do
      if god_is_running
        within current_path do
          # quits god and terminates all tasks
          execute :bundle, "exec god terminate"
        end
      end
    end
  end

  # this set of tasks does manual starting/stopping of solr and
  # unicorn, which we no longer need since we use god. but keeping it
  # around just in case...
  # after 'deploy:started', 'deploy:solr_stop'
  # after 'deploy:started', 'deploy:unicorn_stop'
  # after 'deploy:publishing', 'deploy:solr_update'
  # after 'deploy:publishing', 'deploy:solr_start'
  # after 'deploy:publishing', 'deploy:unicorn_start'

  after 'deploy:started', 'deploy:god_stop'
  after 'deploy:publishing', 'deploy:mkdir_pids'
  after 'deploy:publishing', 'deploy:god_start'

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end
