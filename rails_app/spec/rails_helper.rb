# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'

require 'simplecov'

# filter out legacy code from coverage
SimpleCov.start 'rails' do
  add_filter 'lib/sdbmss/legacy.rb'
  add_filter 'lib/sdbmss/csv.rb'
  add_filter 'lib/sdbmss/viaf_reconcilliation.rb'
end

puts 'SimpleCov started'

require 'spec_helper'
require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

require 'capybara/rails'
require 'factory_girl_rails'
require 'warden/test/helpers'

require 'capybara-screenshot/rspec'

Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }

module TestSuiteSetupHelpers
  extend self

  SOLR_TEST_MODELS = [Entry, Name, Source, Manuscript, Language, Place].freeze

  # JS examples reseed a truncated MySQL database. Disabling FK checks keeps
  # truncation/reseed cheap and avoids ordering every table delete manually.
  def with_foreign_key_checks_disabled
    ActiveRecord::Base.connection.execute('SET FOREIGN_KEY_CHECKS=0')
    yield
  ensure
    ActiveRecord::Base.connection.execute('SET FOREIGN_KEY_CHECKS=1')
  end

  def solr_test_uri
    @solr_test_uri ||= URI(ENV['SOLR_TEST_URL'] || 'http://localhost:8983/solr/test')
  end

  def solr_http
    http = Net::HTTP.new(solr_test_uri.host, solr_test_uri.port)
    http.read_timeout = 30
    http
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

  # JS examples rely on Solr-backed search. Clearing it explicitly is faster
  # and more predictable than trying to keep incremental state in sync.
  def delete_all_solr_docs!
    solr_http.post(
      "#{solr_test_uri.path}/update?commit=true",
      '<delete><query>*:*</query></delete>',
      'Content-Type' => 'application/xml'
    )
  end

  def optimize_solr_index!
    solr_http.post(
      "#{solr_test_uri.path}/update?optimize=true&waitFlush=false&waitSearcher=false",
      '<optimize/>',
      'Content-Type' => 'application/xml'
    )
  end

  # Most specs only need a small set of models indexed in test. Keeping that
  # list explicit keeps suite setup cost bounded.
  def reindex_solr_models!(models = SOLR_TEST_MODELS, per_model_logging: false)
    models.each do |model|
      begin
        Sunspot.index(model.all)
      rescue => e
        raise unless per_model_logging

        log_setup_warning("Solr index #{model} after JS test failed: #{e.message}")
      end
    end
    Sunspot.commit
  end

  # After JS truncation we rebuild Solr from the canonical database state
  # instead of trusting any incremental callbacks that ran during the example.
  def flush_and_reindex_solr_after_js!
    delete_all_solr_docs!
    reindex_solr_models!(SOLR_TEST_MODELS, per_model_logging: true)
  rescue StandardError => e
    log_setup_warning("Solr flush after JS test failed: #{e.message}")
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
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  #
  # must be false for DatabaseCleaner per-example strategy to work
  # (Poltergeist is gone; project now uses Cuprite)
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

  config.include Warden::Test::Helpers
  config.include SDBMSS::Capybara::AlertConfirmer
  config.include SDBMSS::Capybara::Login

  config.before(:suite) do
    # Start from a fully truncated DB, then rebuild the baseline records and
    # a minimal Solr index once for the whole suite.
    TestSuiteSetupHelpers.with_foreign_key_checks_disabled do
      DatabaseCleaner.clean_with(:truncation)
      begin
        TestSuiteSetupHelpers.delete_all_solr_docs!
      rescue => e
        TestSuiteSetupHelpers.log_setup_warning("Solr delete-all before suite failed: #{e.message}")
      end
      TestSuiteSetupHelpers.with_seed_retries('Before-suite seed') do
        TestSuiteSetupHelpers.seed_reference_data!
      end
    end

    begin
      TestSuiteSetupHelpers.reindex_solr_models!([Entry])
    rescue => e
      TestSuiteSetupHelpers.log_setup_warning("Solr index before suite failed: #{e.message}")
    end

    begin
      TestSuiteSetupHelpers.optimize_solr_index!
    rescue => e
      TestSuiteSetupHelpers.log_setup_warning("Solr optimize before suite failed: #{e.message}")
    end
  end

  config.before(:each) do |example|
    # Replace the Sunspot session with a fresh ThreadLocalSessionProxy so that
    # every thread (test thread AND WEBrick server thread) gets new RSolr
    # connections, eliminating stale socket errors from previous tests.
    # If the suite eventually runs under Puma/system-test infrastructure with a
    # cleaner app-server lifecycle, this JS-only reset is worth reevaluating.
    Sunspot.session = Sunspot::Rails.build_session if example.metadata[:js]
    # Suppress User#perform_index_tasks globally (patches the class, visible to
    # ALL threads including WEBrick).  Devise login updates the User record
    # (Trackable), which fires after_save :perform_index_tasks → Sunspot.index →
    # RSolr POST.  Stubbing this one callback prevents Net::ReadTimeout in
    # WEBrick while leaving all other AR Sunspot callbacks (Comment, Place, etc.)
    # intact so those records are indexed normally and searches still work.
    allow_any_instance_of(User).to receive(:perform_index_tasks)
    DatabaseCleaner.strategy = example.metadata[:js] ? :truncation : :transaction
    DatabaseCleaner.start
  end

  config.after(:each) do |example|
    if example.metadata[:js]
      # Reset browser BEFORE the slow re-seeding so Capybara's own cleanup
      # hook (which runs after ours in LIFO order) doesn't time out waiting
      # for a browser that has been idle during Solr callbacks.
      Capybara.reset_sessions!
      # Brief pause to let WEBrick finish any in-flight request that may
      # hold a DB lock before we truncate, preventing deadlock on reseed.
      # This is another WEBrick-era workaround to revisit if the suite moves
      # to Puma and we can validate a cleaner request shutdown path.
      sleep 1
    end
    DatabaseCleaner.clean
    if example.metadata[:js]
      # Suppress Solr during re-seeding: AR after_commit callbacks would try
      # to hit Solr on every record created, causing Net::ReadTimeout on stale
      # connections and corrupting the Sunspot connection pool for subsequent
      # tests.
      # If server/request lifecycle becomes less fragile under Puma, we may be
      # able to replace this with narrower indexing control.
      TestSuiteSetupHelpers.with_foreign_key_checks_disabled do
        sunspot_session = Sunspot.session
        Sunspot.session = Sunspot::Rails::StubSessionProxy.new(sunspot_session)
        begin
          TestSuiteSetupHelpers.with_seed_retries('Reseed') do
            TestSuiteSetupHelpers.seed_reference_data!
          end
        ensure
          Sunspot.session = sunspot_session
        end
      end
      TestSuiteSetupHelpers.flush_and_reindex_solr_after_js!
    end

    Warden.test_reset!
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
