
require 'pathname'

pid File.expand_path("../../tmp/pids/unicorn.pid", __FILE__)

# Web Console (and any in-console debugger) keeps state per worker; multiple workers
# route follow-up requests to a different process and you get "Session ... is no longer
# available in memory". Use a single worker in development.
worker_processes(
  case
  when (wc = ENV["WEB_CONCURRENCY"]) && !wc.empty?
    Integer(wc)
  when ENV["RAILS_ENV"] == "development"
    1
  else
    4
  end
)

# Give debugger sessions time to work (byebug, web-console, etc.)
timeout(ENV["RAILS_ENV"] == "development" ? 86_400 : 60)

#logger Logger.new(File.expand_path("../../log/unicorn.log", __FILE__))
logger Logger.new(STDOUT)
