require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SDBMSS
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Eastern Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.autoload_paths << Rails.root.join('lib')

    config.eager_load_paths << Rails.root.join('lib')

    config.active_job.queue_adapter = :delayed_job

    # custom SDBM variables
    config.bunny_connection = Bunny.new(:host => 'rabbitmq', :port => 5672, :user => ENV["RABBIT_USER"], :pass => ENV["RABBIT_PASSWORD"], :vhost => "/")

    config.sdbmss_allow_user_signup = true

    config.sdbmss_index_after_update_enabled = true

    # this is passed into Blacklight configuration and used by our own
    # ResourceSearch mechanism
    config.sdbmss_max_search_results = 500000

    config.sdbmss_show_testing_message = false

  end
  
end