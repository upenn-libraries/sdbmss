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

    if Rails.env.test?
        config.bunny_connection = Bunny.new(:host => 'localhost', :port => 5672, :user => ENV["RABBIT_USER"], :pass => ENV["RABBIT_PASSWORD"], :vhost => "/")
    else
        config.bunny_connection = Bunny.new(:host => 'rabbitmq', :port => 5672, :user => ENV["RABBIT_USER"], :pass => ENV["RABBIT_PASSWORD"], :vhost => "/")
    end
=begin
    config.bunny_connection.start
    ch = config.bunny_connection.create_channel
    queue = ch.queue("sdbm_status")
    queue.subscribe(block: false) do |_delivery_info, _properties, body|
        contents = JSON.parse(body)
        if (jena_response = JenaResponse.find(contents['id']))
            if contents['code'] == '200'
                puts "Jena Update was Successful!"
                # success, delete
                jena_response.destroy
            else
                if jena_response.tries < 3
                    puts "Failed. Resending..."
                    jena_response.update(tries: jena_response.tries + 1, message: "#{contents['code']}: #{contents['message']}")
                    # fix me: handle for DESTROY as well
                    if jena_response.record.present?
                        jena_response.record.update_bunny(jena_response.id)
                    else
                        jena_response.record.destroy_bunny(jena_response.id)
                    end
                else
                    puts "Failed. Response record retained."
                    jena_response.update(status: -1)
                end
                # resend, increment sent-counter
            end
        else
            # no longer exists
        end
    end

    ch.close()
=end
    config.sdbmss_allow_user_signup = true

    config.sdbmss_index_after_update_enabled = true

    # this is passed into Blacklight configuration and used by our own
    # ResourceSearch mechanism
    config.sdbmss_max_search_results = 500000

    config.sdbmss_show_testing_message = false

  end
  
end