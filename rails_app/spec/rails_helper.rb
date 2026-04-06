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

  config.include SDBMSS::Capybara::AlertConfirmer
  config.include SDBMSS::Capybara::Login

  config.before(:suite) do
    # Disable FK checks before truncation so MySQL can truncate tables
    # that have FK references (e.g. users table referenced by many others).
    ActiveRecord::Base.connection.execute('SET FOREIGN_KEY_CHECKS=0')
    DatabaseCleaner.clean_with(:truncation)
    # Delete all Solr documents directly via HTTP so stale entries from
    # previous test runs don't survive into this suite.  Sunspot.remove_all!
    # goes through the session (which may itself be in a bad state if Solr
    # was previously stuck), so we hit the update handler directly instead.
    begin
      require 'net/http'
      require 'uri'
      solr_url = URI(ENV['SOLR_TEST_URL'] || 'http://localhost:8983/solr/test')
      http = Net::HTTP.new(solr_url.host, solr_url.port)
      http.read_timeout = 30
      http.post(
        "#{solr_url.path}/update?commit=true",
        '<delete><query>*:*</query></delete>',
        'Content-Type' => 'application/xml'
      )
    rescue => e
      Rails.logger.warn "Solr delete-all before suite failed: #{e.message}"
    end
    SDBMSS::SeedData.create
    SDBMSS::ReferenceData.create_all
    SDBMSS::Mysql.create_functions
    ActiveRecord::Base.connection.execute('SET FOREIGN_KEY_CHECKS=1')
    begin
      Sunspot.index(Entry.all)
      Sunspot.commit
    rescue => e
      Rails.logger.warn "Solr index before suite failed: #{e.message}"
    end
    begin
      # Optimize the index (merge segments, prune deleted docs) so repeated test
      # runs don't accumulate a large transaction log that eventually blocks
      # Solr commits.  waitFlush/waitSearcher=false returns immediately.
      require 'net/http'
      solr_url = URI(ENV['SOLR_TEST_URL'] || 'http://localhost:8983/solr/test')
      Net::HTTP.new(solr_url.host, solr_url.port).post(
        "#{solr_url.path}/update?optimize=true&waitFlush=false&waitSearcher=false",
        '<optimize/>',
        'Content-Type' => 'application/xml'
      )
    rescue => e
      Rails.logger.warn "Solr optimize before suite failed: #{e.message}"
    end
  end

  config.before(:each) do |example|
    # Replace the Sunspot session with a fresh ThreadLocalSessionProxy so that
    # every thread (test thread AND WEBrick server thread) gets new RSolr
    # connections, eliminating stale socket errors from previous tests.
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
    end
    DatabaseCleaner.clean
    if example.metadata[:js]
      ActiveRecord::Base.connection.execute('SET FOREIGN_KEY_CHECKS=0')
      # Suppress Solr during re-seeding: AR after_commit callbacks would try
      # to hit Solr on every record created, causing Net::ReadTimeout on stale
      # connections and corrupting the Sunspot connection pool for subsequent
      # tests.
      sunspot_session = Sunspot.session
      Sunspot.session = Sunspot::Rails::StubSessionProxy.new(sunspot_session)
      begin
        SDBMSS::SeedData.create
        SDBMSS::ReferenceData.create_all
        SDBMSS::Mysql.create_functions
      ensure
        Sunspot.session = sunspot_session
        ActiveRecord::Base.connection.execute('SET FOREIGN_KEY_CHECKS=1')
      end
      # Flush stale Solr docs that tests may have created via the browser.
      # After truncation+reseed, any indexed records beyond the seeded set
      # have no corresponding DB rows; the next Solr search returns them,
      # causing entry_path(nil) crashes.  Delete all Solr docs and re-index
      # all searchable models so that the next test starts with a clean,
      # consistent Solr state matching the reseeded DB.
      begin
        require 'uri'
        solr_url = URI(ENV['SOLR_TEST_URL'] || 'http://localhost:8983/solr/test')
        http = Net::HTTP.new(solr_url.host, solr_url.port)
        http.read_timeout = 30
        http.post(
          "#{solr_url.path}/update?commit=true",
          '<delete><query>*:*</query></delete>',
          'Content-Type' => 'application/xml'
        )
        [Entry, Name, Source, Manuscript, Language, Place].each { |model| Sunspot.index(model.all) }
        Sunspot.commit
      # If the HTTP delete fails, skip re-index — no point indexing into a broken Solr.
      rescue StandardError => e
        Rails.logger.warn "Solr flush after JS test failed: #{e.message}"
      end
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
