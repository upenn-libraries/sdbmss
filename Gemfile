source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~>4.2.1'

# Use sqlite3 as the database for Active Record
# gem 'sqlite3', group: :development

gem 'mysql2', '~> 0.3.0'

# XML parsing. Other gems require nokogiri as well, but we may as well
# require it too.
gem 'nokogiri', '~> 1.6'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0.3'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '~> 2.5.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer',  platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails', '~> 3.1.0'
gem 'jquery-ui-rails', '~> 5.0.3'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks', '~> 2.5.0'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.2.0'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use unicorn as the app server
gem 'unicorn', '~> 4.8.0'

# Use debugger
# gem 'debugger', group: [:development, :test]

# Blacklight
gem "blacklight", "~> 5.13.0"
gem "jettywrapper", "~> 1.8.0"
gem "blacklight_advanced_search", "~> 5.1.3"

# For authentication; used by Blacklight and by SDBMSS
gem "devise", "~> 3.4.0"
gem "devise-guests", "~> 0.3.0"

# For roles and permissions checking
gem "cancancan", "~> 1.10.1"

# For indexing records in Solr
gem 'sunspot_rails', '~> 2.2.0'
gem 'sunspot_solr', '~> 2.2.0'

# Use database as session store
gem 'activerecord-session_store', '~> 0.1.0'

# for calculating string similarity
gem 'levenshtein', '~> 0.2.2'

# for auditing model changes
gem 'paper_trail', '~> 4.0.0.beta'

# natural language date parser
gem 'chronic', '~> 0.10.2'

# async background job processing
gem 'delayed_job', '~> 4.0.6'
gem 'delayed_job_active_record', '~> 4.0.3'

# neeeded for delayed_job script to run in background
gem "daemons", '~> 1.2.2'

# manage and monitor application processes
gem "god", "~> 0.13.6"

# ability to put entire app in maintenance mode
gem "turnout", "~> 2.1.0"

# send email notifications on app exceptions
gem "exception_notification", "~> 4.1.1"

# bundle exec rake doc:rails generates the Rails API under doc/api.
group :doc do
  gem 'sdoc', '~> 0.4.0'
  gem 'yard', '~> 0.8.0'
end

group :development do
  # in-browser console
  gem 'web-console', '~> 2.1'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring', '~> 1.1.0'
  # Use Capistrano for deployment
  gem 'capistrano-rails', '~> 1.1.0'

  # This can autogenerate ERD diagrams from ActiveRecord models and
  # schema.
  #gem 'rails-erd', '~> 1.3.1'
end

group :test, :development do
  gem 'rspec-rails', '~> 3.1.0'
  gem 'capybara', '~> 2.4.4'
  gem "factory_girl_rails", "~> 4.0"
  gem 'poltergeist', '~> 1.6.0'
  gem 'simplecov', :require => false
end
