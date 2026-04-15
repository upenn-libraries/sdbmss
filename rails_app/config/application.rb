require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SDBMSS
  class Application < Rails::Application
    config.load_defaults "6.1"

    # TODO: audit belongs_to associations for optional: true, then remove this override
    config.active_record.belongs_to_required_by_default = false

    # Disable SassC as CSS compressor because it cannot handle modern CSS var() syntax in vendor DataTables stylesheets
    config.assets.css_compressor = nil

    # Psych 3.1+ restricts YAML deserialization to safe classes by default.
    # The ActiveRecord session store and Blacklight save Ruby objects (like
    # HashWithIndifferentAccess) into YAML-serialized session data.
    config.active_record.yaml_column_permitted_classes = [
      ActiveSupport::HashWithIndifferentAccess,
      Symbol
    ]

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
