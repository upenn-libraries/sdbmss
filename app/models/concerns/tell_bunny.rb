module TellBunny

  require 'bunny'

  extend ActiveSupport::Concern

  HOST = 'rabbitmq'

  included do
    after_commit :update_bunny
    # after destroy
    after_destroy :destroy_bunny

  end

  def to_rdf
    %Q(
      # sdbm:names/#{id} sdbm:names_id #{id}      
    )
  end
  
  #private

  def update_bunny
    if self.persisted?
      #connection = Bunny.new(:host => HOST, :port => 5672, :user => "sdbm", :pass => "sdbm", :vhost => "/")
      begin

        Rails.configuration.bunny_connection.start

        ch = Rails.configuration.bunny_connection.create_channel

        q = ch.queue("sdbm")

        q.publish("#{self.to_rdf}")

        ch.close()

      rescue Bunny::TCPConnectionFailed => e
        puts "(Update) - Connection to RabbitMQ server failed"
      else
        ch.close() if defined? ch
      end
    end
  end

  def destroy_bunny
    begin
      puts "AFTER DESTROY"
      #connection = Bunny.new(:host => HOST, :port => 5672, :user => "sdbm", :pass => "sdbm", :vhost => "/")
      Rails.configuration.bunny_connection.start

      ch = Rails.configuration.bunny_connection.create_channel

      q = ch.queue("sdbm")

      q.publish("DESTROY sdbm:#{self.class.name.pluralize.underscore}/#{self.id}")

      ch.close()

    rescue Bunny::TCPConnectionFailed => e
      puts "(Destroy) - Connection to RabbitMQ server failed"
    else
        ch.close() if defined? ch      
    end
  end
end