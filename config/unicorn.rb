
require 'pathname'

pid Pathname.new(File.expand_path("../../..", __FILE__)).join("shared", "pids", "unicorn.pid").to_s

worker_processes 4

