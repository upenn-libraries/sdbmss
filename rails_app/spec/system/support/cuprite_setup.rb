# frozen_string_literal: true

# Cuprite config based on https://evilmartians.com/chronicles/system-of-a-test-setting-up-end-to-end-rails-testing

# First, load Cuprite Capybara integration
require 'capybara/cuprite'

# Then, we need to register our driver to be able to use it later
# with #driven_by method.
# NOTE: The name :cuprite is already registered by Rails.
# See https://github.com/rubycdp/cuprite/issues/180
Capybara.register_driver(:better_cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    **{
      window_size: [1200, 800],
      browser_options: remote_chrome ? { 'no-sandbox' => nil } : {},
      inspector: true,
      js_errors: true
    }
  )
end

# Configure Capybara to use :better_cuprite driver by default
Capybara.default_driver = Capybara.javascript_driver = :better_cuprite

