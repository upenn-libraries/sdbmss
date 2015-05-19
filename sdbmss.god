
# god configuration

rails_root = Dir.pwd

God.watch do |w|
  w.name = "unicorn"

  w.dir = rails_root
  w.start = "cd #{rails_root} && bundle exec unicorn -c config/unicorn.rb -D"

  unicorn_pid_file = File.join(rails_root, "/tmp/pids/unicorn.pid")

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
  w.stop = "bundle exec rake sunspot:solr:stop"
  w.keepalive
end