# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
ENV['DEBUGGER__::DISABLE'] ||= '1'

if ENV['COVERAGE'] == '1'
  require 'simplecov'

  # filter out legacy code from coverage
  SimpleCov.start 'rails' do
    add_filter 'lib/sdbmss/legacy.rb'
    add_filter 'lib/sdbmss/csv.rb'
    add_filter 'lib/sdbmss/viaf_reconcilliation.rb'
  end

  puts 'SimpleCov started'
end

require 'spec_helper'
require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

require 'capybara/rails'
require 'factory_bot_rails'
require 'warden/test/helpers'

require 'capybara-screenshot/rspec'
require 'test_prof/recipes/rspec/let_it_be'

Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }

module TestSuiteSetupHelpers
  extend self

  # JS examples reseed a truncated MySQL database. Disabling FK checks keeps
  # truncation/reseed cheap and avoids ordering every table delete manually.
  def with_foreign_key_checks_disabled
    ActiveRecord::Base.connection.execute('SET FOREIGN_KEY_CHECKS=0')
    yield
  ensure
    ActiveRecord::Base.connection.execute('SET FOREIGN_KEY_CHECKS=1')
  end

  def suite_logger
    Rails.logger
  end

  def log_setup_warning(message)
    suite_logger.warn(message)
  end

  # Test setup occasionally hits transient deadlocks or duplicate-key races
  # while the browser thread and reseed path overlap. Retry only those known
  # bootstrap failures rather than hiding unrelated setup errors.
  def with_seed_retries(label)
    attempts = 0
    begin
      yield
    rescue Mysql2::Error => e
      attempts += 1
      if e.message =~ /Deadlock|Duplicate entry/ && attempts <= 3
        log_setup_warning("#{label} attempt #{attempts} failed (#{e.message.split(':').first}), retrying...")
        sleep(0.5 * attempts)
        retry
      end
      raise
    end
  end

  # The suite depends on baseline seed data, reference data, and custom MySQL
  # functions being present after each full truncation.
  def seed_reference_data!
    SDBMSS::SeedData.create
    SDBMSS::ReferenceData.create_all
    SDBMSS::Mysql.create_functions
  end

end

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# Shared test-support code is auto-required from spec/support.

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = ["#{::Rails.root}/spec/fixtures"]

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  #
  # Browser specs run against Puma with a shared ActiveRecord connection, so
  # examples can stay transaction-based instead of truncating per example.
  config.use_transactional_fixtures = true

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

  # FactoryBot support
  config.include FactoryBot::Syntax::Methods

  config.include Warden::Test::Helpers
  config.include SDBMSS::Capybara::AlertConfirmer
  config.include SDBMSS::Capybara::Login
  config.include TestSuiteSetupHelpers

  config.before(:suite) do
    # Start from a fully truncated DB, then rebuild the baseline records and
    # a minimal Solr index once for the whole suite.
    SharedConnection.connection = ActiveRecord::Base.connection
    TestSuiteSetupHelpers.with_foreign_key_checks_disabled do
      DatabaseCleaner.clean_with(:truncation)
      begin
        SolrTools.clear!
      rescue => e
        TestSuiteSetupHelpers.log_setup_warning("Solr delete-all before suite failed: #{e.message}")
      end
      TestSuiteSetupHelpers.with_seed_retries('Before-suite seed') do
        TestSuiteSetupHelpers.seed_reference_data!
      end
    end

    begin
      SolrTools.reindex_models!([Entry])
    rescue => e
      TestSuiteSetupHelpers.log_setup_warning("Solr index before suite failed: #{e.message}")
    end

    begin
      SolrTools.optimize!
    rescue => e
      TestSuiteSetupHelpers.log_setup_warning("Solr optimize before suite failed: #{e.message}")
    end
  end

  config.before(:each) do |example|
    SharedConnection.connection = ActiveRecord::Base.connection if example.metadata[:js]

    # Clear the AR query cache between JS examples. SharedConnection reuses the
    # same DB connection across tests, so rolled-back transactions can leave
    # stale query-cache entries (e.g. SourceType.auction_catalog → nil) that
    # cause seed-data lookups to return nil in subsequent tests.
    ActiveRecord::Base.connection.clear_query_cache if example.metadata[:js]

    # Replace the Sunspot session with a fresh ThreadLocalSessionProxy so that
    # every thread (test thread AND Puma server thread) gets new RSolr
    # connections, eliminating stale socket errors from previous tests.
    Sunspot.session = Sunspot::Rails.build_session if example.metadata[:js]
    # Suppress User#perform_index_tasks globally (patches the class, visible to
    # ALL threads including the app server). Devise login updates the User record
    # (Trackable), which fires after_save :perform_index_tasks → Sunspot.index →
    # RSolr POST.  Stubbing this one callback prevents Net::ReadTimeout in
    # Puma while leaving all other AR Sunspot callbacks (Comment, Place, etc.)
    # intact so those records are indexed normally and searches still work.
    allow_any_instance_of(User).to receive(:perform_index_tasks)
  end

  config.before(:each, :solr) do
    SampleIndexer.clear!
  end

  config.append_after(:each) do |example|
    Warden.test_reset!
  end

  config.after(:suite) do
    begin
      SolrTools.clear!
    rescue => e
      TestSuiteSetupHelpers.log_setup_warning("Solr delete-all after suite failed: #{e.message}")
    end
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
