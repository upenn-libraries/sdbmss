module TellBunny

  require 'bunny'

  extend ActiveSupport::Concern

  HOST = 'rabbitmq'

  included do
    after_commit :update_bunny
    # after destroy
    after_destroy :destroy_bunny
    has_many :jena_responses, as: :record
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

        # delete old response records:
        self.jena_responses.destroy_all

        # create the latest response record
        jena_reponse = JenaResponse.create!(record: self, status: 0)

        message = self.to_rdf
        message[:action] = "update"
        message[:response_id] = jena_reponse.id
        q.publish(message.to_json)

        ch.close()

      rescue Bunny::TCPConnectionFailed => e
        puts "(Update) - Connection to RabbitMQ server failed"
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

      # delete old response records:
      self.jena_responses.destroy_all

      # create the latest response record
      jena_reponse = JenaResponse.create!(record: self, status: 0)

      message = self.to_rdf
      message[:response_id] = jena_reponse.id
      message[:action] = "destroy"
      q.publish(message.to_json)

      ch.close()

    rescue Bunny::TCPConnectionFailed => e
      puts "(Destroy) - Connection to RabbitMQ server failed"
    end
  end
end