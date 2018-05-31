
require 'pathname'

pid File.expand_path("../../tmp/pids/unicorn.pid", __FILE__)

worker_processes 4

#logger Logger.new(File.expand_path("../../log/unicorn.log", __FILE__))
logger Logger.new(STDOUT)
