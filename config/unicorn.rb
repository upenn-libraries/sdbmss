
require 'pathname'

pid Pathname.new(File.expand_path("../..", __FILE__)).join("tmp", "pids", "unicorn.pid").to_s

worker_processes 4

