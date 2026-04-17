workers(
  case
  when (wc = ENV["WEB_CONCURRENCY"]) && !wc.empty?
    Integer(wc)
  when ENV["RAILS_ENV"] == "development"
    0
  else
    4
  end
)

threads_count = ENV.fetch("RAILS_MAX_THREADS", 5).to_i
threads 0, threads_count

port ENV.fetch("PORT", 3000)
environment ENV.fetch("RAILS_ENV", "development")
pidfile ENV.fetch("PIDFILE", "tmp/pids/puma.pid")

# Give debugger sessions time to work
if ENV["RAILS_ENV"] == "development"
  worker_timeout 86_400
else
  worker_timeout 60
end

# Allow puma to be restarted by `rails restart` command
plugin :tmp_restart
