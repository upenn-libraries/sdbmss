
# god configuration

rails_root = Dir.pwd

God.watch do |w|
  w.name = "unicorn"

  w.dir = rails_root
  w.start = "cd #{rails_root} && bundle exec unicorn -c config/unicorn.rb -D"

  unicorn_pid_file = File.expand_path(File.join(rails_root, "../../shared/pids/unicorn.pid"))

  # QUIT gracefully shuts down workers
  w.stop = "kill -QUIT `cat #{unicorn_pid_file}`"

  # USR2 causes the master to re-create itself and spawn a new worker pool
  w.restart = "kill -USR2 `cat #{unicorn_pid_file}`"

  w.pid_file = unicorn_pid_file

  w.behavior(:clean_pid_file)

  w.keepalive
end

God.watch do |w|
  w.name = "delayed_job"
  w.dir = rails_root
  w.start = "bundle exec rake jobs:work"
  w.keepalive
end

God.watch do |w|
  w.name = "solr"
  w.dir = rails_root
  w.start = "bundle exec rake sunspot:solr:run"
  # solr isn't writing pid files out correctly for some reason, so we
  # let god track the PID and kill the process, instead of specifying
  # a stop command
  # w.stop = "bundle exec rake sunspot:solr:stop"
  w.keepalive
end
