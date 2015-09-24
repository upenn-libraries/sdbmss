# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

ZIP_URL = "https://github.com/projectblacklight/blacklight-jetty/archive/v4.9.0.zip"
require 'jettywrapper'

# clear out the default task
Rake::Task["default"].clear

# (re)define default to show a warning
task default: %w[show_warning]

task :show_warning do
  puts "There is no default task to run. This is deliberate, to avoid rake's typical behavior of running the test suite, which is destructive."
end
