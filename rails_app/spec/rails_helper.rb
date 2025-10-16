# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'

require 'simplecov'

# filter out legacy code from coverage
SimpleCov.start 'rails' do
  add_filter 'lib/sdbmss/legacy.rb'
  add_filter 'lib/sdbmss/csv.rb'
  add_filter 'lib/sdbmss/viaf_reconcilliation.rb'
end

puts "SimpleCov started"

require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

require 'capybara/rails'
require 'factory_girl_rails'

require 'capybara-screenshot/rspec'

require_relative './helpers'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  #
  # set this to false so that any writes to the db can be seen by
  # poltergeist driver
  config.use_transactional_fixtures = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # FactoryGirl support
  config.include FactoryGirl::Syntax::Methods

  config.include SDBMSS::Capybara::AlertConfirmer
  config.include SDBMSS::Capybara::Login

  excluded_tables = %w[pages] # Don't delete static page paths

  DatabaseCleaner.clean_with(:truncation, { except: excluded_tables })
  DatabaseCleaner.start
  DatabaseCleaner.clean
  Sunspot::remove_all!
  SDBMSS::SeedData.create
  SDBMSS::ReferenceData.create_all
  SDBMSS::Mysql.create_functions
  config.before(:all) do
  end

  # This is commented out b/c it seems the browser doesn't always hang
  # around long enough after each scenario to capture a screenshot:
  # many failures generate blank screenshot images.
  #
  # config.after(:each) do |scenario|
  #   if scenario.exception && scenario.metadata[:js]
  #     meta = scenario.metadata
  #     filename = File.basename(meta[:file_path])
  #     line_number = meta[:line_number]
  #     screenshot_name = "screenshot-#{filename}-#{line_number}.png"
  #     screenshot_path = "#{Rails.root.join("tmp")}/#{screenshot_name}"
  #     page.save_screenshot(screenshot_path, :full => true)
  #     puts meta[:full_description] + "\n Screenshot: #{screenshot_path}"
  #   end
  # end

end
