source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~>4.2.11.1'

gem "actionview", ">= 4.2.11.1"
gem "nokogiri", "= 1.8.5"
gem "activejob", ">= 4.2.11"
gem "rack", ">= 1.6.11"
gem "loofah", ">= 2.2.3"
gem "rubyzip", ">= 1.2.2"
gem "ffi", ">= 1.9.24"
gem "sprockets", ">= 3.7.2"
gem "net-ssh", "< 5.0"
gem "kramdown", "<= 1.16.2"
gem "sassc", "<= 1.12.1"
gem 'autoprefixer-rails', '~> 7.1.6'

gem 'invisible_captcha'

gem 'actionview-encoded_mail_to'

# gem "bootstrap-sass", ">= 3.4.1"
    
# Use sqlite3 as the database for Active Record
# gem 'sqlite3', group: :development

gem 'logger', '~> 1.2.7'

gem 'mysql2', '~> 0.3.18'

# XML parsing. Other gems require nokogiri as well, but we may as well
# require it too.
# gem 'nokogiri', '~> 1.8.2'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0.3'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '~> 2.7.2'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer',  platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails', '~> 4.2.1'
gem 'jquery-ui-rails', '~> 5.0.3'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks', '~> 2.5.0'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.2.0'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use unicorn as the app server
gem 'unicorn', '~> 4.9.0'
gem 'unicorn-rails'
gem 'rack-handlers'
# Use debugger
# gem 'debugger', group: [:development, :test]

# Blacklight
gem "blacklight", "~> 5.14.0"
gem "jettywrapper", "~> 2.0.3"
gem "blacklight_advanced_search", "~> 5.1.3"

# For authentication; used by Blacklight and by SDBMSS
gem "devise", "~> 4.7.1"
gem "devise-guests", "~> 0.3.0"

# For roles and permissions checking
gem "cancancan", "~> 1.12.0"

# For indexing records in Solr
gem 'sunspot_rails', '2.2.0' # updating sunspot beyond 2.2.0 causes SOLR nullPointerException errors...
gem 'sunspot_solr', '2.2.0'

# Use database as session store
gem 'activerecord-session_store', '~> 0.1.0'

# for calculating string similarity
gem 'levenshtein', '~> 0.2.2'

# for auditing model changes
gem 'paper_trail', '~> 4.0.0'

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

# converts fixnums to string equivalents
gem "number_to", "~> 0.7.1"

# empties db after each group of tests
gem "database_cleaner", "~> 1.4.1"

# for compressing csv exports to .zip
# gem "rubyzip"

#gem "linkeddata"
#gem "rdf-turtle"
gem "bunny"

gem 'data-confirm-modal'

gem 'thredded', '~> 0.9.4'

gem 'whenever', :require => false

gem 'rake', '< 11.0'

gem 'codemirror-rails'

# bundle exec rake doc:rails generates the Rails API under doc/api.
group :doc do
  gem 'sdoc', '~> 0.4.0'
  gem 'yard', '~> 0.9.11'
end

group :development do
  # in-browser console
  gem 'web-console', '~> 2.1'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring', '~> 1.1.0'
  # Use Capistrano for deployment
  gem 'capistrano-rails', '~> 1.1.0'
  gem 'pry-rails'

  # This can autogenerate ERD diagrams from ActiveRecord models and
  # schema. This causes problems when it's enabled for anything
  # besides running "bundle exec erd" (but I can't remember exactly
  # what the probs were) which is why it's commented out.
  # gem 'rails-erd', require: false, group: :development
end

group :test, :development do
  gem 'rspec-rails', '~> 3.1.0'
  gem 'capybara', '~> 2.4.4'
  gem 'capybara-screenshot', '~> 1.0.3'
  gem "factory_girl_rails", "~> 4.0"
  gem 'poltergeist', '~> 1.6.0'
  gem 'simplecov', :require => false
end