# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

env :PATH, ENV['PATH']
env :SDBMSS_NOTIFY_EMAIL, ENV['SDBMSS_NOTIFY_EMAIL']
env :SDBMSS_NOTIFY_EMAIL_PASSWORD, ENV['SDBMSS_NOTIFY_EMAIL_PASSWORD']
#env :SDBMSS_DB_HOST, ENV['SDBMSS_DB_HOST']
env :MYSQL_DATABASE, ENV['MYSQL_DATABASE']
env :MYSQL_PASSWORD, ENV['MYSQL_PASSWORD']
env :MYSQL_USER, ENV['MYSQL_USER']

set :output, '/tmp/cron.log'
set :environment, "development"

every :tuesday, :at => '1am' do
  runner "Language.delay.do_csv_dump"
  runner "Place.delay.do_csv_dump"
  runner "Source.delay.do_csv_dump"
  runner "Name.delay.do_csv_dump"
  runner "Entry.delay.do_csv_dump"
end