module TellBunny

  require 'bunny'

  extend ActiveSupport::Concern

  included do
    after_save do |model|
      connection = Bunny.new
      connection.start

      ch = connection.create_channel

      q = ch.queue("sdbm")

      q.publish("#{model.to_rdf}")

      # close the connection
      connection.stop
    end

    # after destroy
    after_destroy do |model|
      puts "AFTER DESTROY"
      connection = Bunny.new
      connection.start

      ch = connection.create_channel

      q = ch.queue("sdbm")

      q.publish("DESTROY sdbm:#{model.class.name.pluralize.underscore}/#{model.id}")

      connection.stop
    end

  end

  # manually add to each class?
  # 
  #x- entries
  #x- entry_titles
  #x- entry_authors
  #x- entry_dates
  #x- entry_scribes
  #x- entry_artists
  #x- entry_places
  #x- entry_languages
  #x- entry_manuscripts
  #x- entry_uses
  #x- entry_materials
  #x- provenance
  #x- sales
  #x- sale_agents
  # 
  #x- places
  #x- languages
  #x- names
  #x- manuscripts
  # 
  #x- sources
  #x- source_agents
  #x- source_types
  # 
  #x- dericci_links
  #x- dericci_records

  def to_rdf
    %Q(
      # sdbm:names/#{id} sdbm:names_id #{id}      
    )
  end
end