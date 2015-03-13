source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~>4.1.7'

# Use sqlite3 as the database for Active Record
# gem 'sqlite3', group: :development

gem 'mysql2', '~> 0.3.0'

# XML parsing. Other gems require nokogiri as well, but we may as well
# require it too.
gem 'nokogiri', '~> 1.6'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.3'

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

# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc
gem 'yard', '~> 0.8.0', group: :doc

# Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
gem 'spring', '~> 1.1.0', group: :development

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use unicorn as the app server
gem 'unicorn', '~> 4.8.0'

# Use Capistrano for deployment
gem 'capistrano-rails', '~> 1.1.0', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

# Blacklight
gem "blacklight", "~> 5.10.2"
gem "jettywrapper", "~> 1.8.0"
# TODO: blacklight_advanced_search 5.1.3 gets rid of deprecation
# warnings from blacklight 5.10.2 but it hasn't been released yet
gem "blacklight_advanced_search", "~> 5.1.2"

# For authentication; used by Blacklight and by SDBMSS
gem "devise", "~> 3.4.0"
gem "devise-guests", "~> 0.3.0"

# For indexing records in Solr
gem 'sunspot_rails', '~> 2.1.0'
gem 'sunspot_solr', '~> 2.1.0'

# Use database as session store
gem 'activerecord-session_store', '~> 0.1.0'

# for testing
group :test, :development do
  gem 'rspec-rails', '~> 3.1.0'
  gem 'capybara', '~> 2.4.4'
  gem "factory_girl_rails", "~> 4.0"
  gem 'poltergeist', '~> 1.6.0'
  gem 'simplecov', :require => false
end

# This can autogenerate ERD diagrams from ActiveRecord models and
# schema.
# gem 'rails-erd', group: :development

# for calculating string similarity
gem 'levenshtein', '~> 0.2.2'
