
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
        entries = entries.load_associations

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

end
