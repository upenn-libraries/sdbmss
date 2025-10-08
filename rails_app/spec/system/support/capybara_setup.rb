# frozen_string_literal: true

# Capybara config based on https://evilmartians.com/chronicles/system-of-a-test-setting-up-end-to-end-rails-testing

# We use a Capybara default value here explicitly.
Capybara.default_max_wait_time = 2

# Where to store system tests artifacts (e.g. screenshots, downloaded files, etc.).
# It could be useful to be able to configure this path from the outside (e.g., on CI).
Capybara.save_path = ENV.fetch('CAPYBARA_ARTIFACTS', './tmp/capybara')

# Make server accessible from the outside world
Capybara.server_host = '0.0.0.0'

# Use a hostname that could be resolved in the internal Docker network
Capybara.app_host = "http://app:3000"
# Capybara.app_host = "http://#{ENV.fetch('APP_HOST', `hostname`.strip&.downcase || '0.0.0.0')}"

RSpec.configure do |config|
  # Not loading Bootstrap Icons from CDN to prevent inconsistent errors from accept_confirm
  config.before(:each, type: :feature) do
    page.driver.browser.url_blacklist = [%r{https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.2/font/bootstrap-icons.css}]
  end
  # Make sure this hook runs before others
  # config.prepend_before(:each, type: :feature) do
  #   # Use JS driver always
  #   driven_by Capybara.javascript_driver
  # end
end
