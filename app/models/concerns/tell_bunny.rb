module TellBunny

  require 'bunny'

  extend ActiveSupport::Concern

  #HOST = "165.123.105.243"
  HOST = 'rabbitmq'

  included do
    after_commit :update_bunny
    # after destroy
    after_destroy :destroy_bunny

  end



  # manually add to each class?
  # 
  #tx- entries
  #tx- entry_titles
  #tx- entry_authors
  #tx- entry_dates
  #tx- entry_scribes
  #tx- entry_artists
  #tx- entry_places
  #tx- entry_languages
  #tx- entry_manuscripts
  #tx- entry_uses
  #tx -entry_materials
  #tx- provenance
  #tx- sales
  #tx- sale_agents
  # 
  #tx- places
  #tx- languages
  #tx- names
  #tx- manuscripts
  # 
  #tx- sources
  #tx- source_agents
  #tx- source_types
  # 
  #tx- dericci_links
  #tx- dericci_records

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

      rescue Bunny::TCPConnectionFailed => e
        puts "(Update) - Connection to RabbitMQ server failed"
        self.delay(run_at: 1.hour.from_now).update_bunny
      end
      # close the connection
      #Rails.configuration.bunny_connection.stop
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

    rescue Bunny::TCPConnectionFailed => e
      puts "(Destroy) - Connection to RabbitMQ server failed"
      self.delay(run_at: 1.hour.from_now).destroy_bunny
    end
    #Rails.configuration.bunny_connection.stop
  end

end