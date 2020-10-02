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

  # inherited and overriden by relevent models.
  # NOTE: use triple single quotes to enclose string literals, to avoid confusion with quotes in the strings themsleves

  def to_rdf
    %Q(
      # sdbm:names/#{id} sdbm:names_id #{id}
    )
  end


  ##
  #  If +value+ is present, return a formatted rdf object string based on +data_type+.
  #
  # @param [Object] value the value of the property object
  #
  def format_triple_object value, data_type, url_base=nil
    return unless value.present?
    case data_type
    when :integer
      "'#{value}'^^xsd:integer"
    when :decimal
      "'#{value}'^^xsd:decimal"
    when :boolean
      "'#{value}'^^xsd:boolean"
    when :string_to_clean
      "'''#{value.to_s.gsub("'", "")}'''"
    when :string
      "'''#{value}'''"
    when :uri
      raise "No `url_base` supplied for #{value}" unless url_base.present?
      "<#{url_base}#{value}>"
    else
      raise "Unknown "
    end
  end

  #private

  def update_bunny(jena_response_id = nil)
    if self.persisted?
      #connection = Bunny.new(:host => HOST, :port => 5672, :user => "sdbm", :pass => "sdbm", :vhost => "/")
      begin

        Rails.configuration.bunny_connection.start

        ch = Rails.configuration.bunny_connection.create_channel

        q = ch.queue("sdbm")

        # create the latest response record UNLESS this is a 'retry'

        if jena_response_id.present? && JenaResponse.exists?(jena_response_id)
          jena_response = JenaResponse.find(jena_response_id)
        else
          # delete old response records:
          self.jena_responses.destroy_all
          jena_response = JenaResponse.create!(record: self, status: 1)
        end

        message = self.to_rdf
        message[:action] = "update"
        message[:response_id] = jena_response.id
        q.publish(message.to_json)

        ch.close()

      rescue Bunny::TCPConnectionFailed => e
        #puts "(Update) - Connection to RabbitMQ server failed"
        self.jena_responses.destroy_all
        JenaResponse.create!(record: self, status: 0, message: "404: Failed to connect from Rails to RabbitMQ: #{e}")
      #rescue StandardError => e
      #  self.jena_responses.destroy_all
      #  JenaResponse.create!(record: self, status: 0, message: "OTHER: Unknown exception: #{e}")
      end
    end
  end

  def destroy_bunny(jena_response_id = nil)
    begin
      puts "AFTER DESTROY"
      #connection = Bunny.new(:host => HOST, :port => 5672, :user => "sdbm", :pass => "sdbm", :vhost => "/")
      Rails.configuration.bunny_connection.start

      ch = Rails.configuration.bunny_connection.create_channel

      q = ch.queue("sdbm")

      # create the latest response record UNLESS this is a 'retry'
      if jena_response_id.present? && JenaResponse.exists?(jena_response_id)
        jena_response = JenaResponse.find(jena_response_id)
      else
        # delete old response records:
        self.jena_responses.destroy_all
        jena_response = JenaResponse.create!(record: self, status: 1)
      end

      message = self.to_rdf
      message[:response_id] = jena_response.id
      message[:action] = "destroy"
      q.publish(message.to_json)

      ch.close()

    rescue Bunny::TCPConnectionFailed => e
      puts "(Destroy) - Connection to RabbitMQ server failed"
      self.jena_responses.destroy_all
      JenaResponse.create!(record: self, status: 0, message: "404: Failed to connect from Rails to RabbitMQ: #{e}")
    end
  end
end