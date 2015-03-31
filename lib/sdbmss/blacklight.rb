
# This module contains customized subclasses of things used by
# Blacklight

module SDBMSS::Blacklight

  # This queues up object ids when #add is called, and fetches
  # everything that's been queued up on a #get for any object
  class ResultSet
    attr_accessor :ids_to_entries

    def initialize
      @ids_to_entries = Hash.new
    end

    def add(object_id)
      @ids_to_entries[object_id] ||= nil
    end

    # returns the model object instance for the object_id
    def get(object_id)
      # Load model objects on demand, only if we haven't loaded them yet
      ids_to_load = @ids_to_entries.select { |id, object| object.nil? }.keys
      if ids_to_load.count > 0
        #puts "Loading: " + ids_to_load.join(",")

        # fetch all objects in a single query for efficiency
        entries = Entry.where(id: ids_to_load)
        entries = entries.with_associations

        entries.each do |entry|
          @ids_to_entries[entry.id] = entry
        end
      end
      @ids_to_entries[object_id]
    end

  end

  # Specialized response that stores an instance of a ResultSet
  class SolrResponse < Blacklight::SolrResponse
    attr_accessor :objects_resultset

  end

  class DocumentPresenter < Blacklight::DocumentPresenter

    # used for html title element
    def document_heading
      return @document.model_object.public_id
    end

  end

  class SearchBuilder < Blacklight::Solr::SearchBuilder
    def show_all_if_no_query(solr_parameters)
      # edismax itself doesn't understand '*' but we can pass in q.alt
      # and it will work for some reason
      solr_parameters['q.alt'] = "*:*" if blacklight_params['q'].blank?
    end
  end

end
