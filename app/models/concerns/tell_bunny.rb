module TellBunny

  require 'bunny'

  extend ActiveSupport::Concern

  included do
    after_save do |model|
      connection = Bunny.new
      connection.start

      ch = connection.create_channel

      q = ch.queue("test")

      q.publish("#{model.to_rdf}")

      # close the connection
      connection.stop
    end

    # after destroy


  end

  # manually add to each class?
  # 
  # entries
  # entry_titles
  # entry_authors
  # entry_dates
  # entry_scribes
  # entry_artists
  # entry_places
  # entry_languages
  # entry_manuscripts
  # entry_uses
  # entry_materials
  # provenance
  # sales
  # sale_agents
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