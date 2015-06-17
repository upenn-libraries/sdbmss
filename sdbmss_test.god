
# god configuration for test environment

rails_root = Dir.pwd

God.watch do |w|
  w.name = "delayed_job_test"
  w.dir = rails_root
  w.start = "bundle exec rake jobs:work"
  w.keepalive
end
