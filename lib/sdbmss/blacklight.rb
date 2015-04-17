
# This module contains customized subclasses of things used by
# Blacklight

module SDBMSS::Blacklight

  # These hardcoded bounds MUST correspond to Solr field definition or
  # things might break or behave weirdly.
  DATE_RANGE_YEAR_MIN = -10000
  DATE_RANGE_YEAR_MAX =  10000
  DATE_RANGE_FULL_MIN = -99999999
  DATE_RANGE_FULL_MAX =  99999999

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

    # This translates a query str of "[year1 TO year2]" in the
    # manuscript_date blacklight parameters field to a str of the form
    # '["minX minY" TO "maxX maxY"]'. We do this translation so that
    # BL params are kept readable and front-end JS can treat date
    # range queries exactly the same as other numeric range queries.
    def translate_manuscript_date(solr_parameters)
      manuscript_date = blacklight_params['manuscript_date']
      if manuscript_date.present?
        m = /\[(.+?) TO (.+?)\]/.match(manuscript_date)
        if m
          from, to = m[1], m[2]

          # we need to buffer, otherwise Solr won't return points that
          # lie exactly on the edge of the search region
          buffer = 0.5
          from = from == '*' ? DATE_RANGE_YEAR_MIN : from.to_i - buffer
          to = to == '*' ? DATE_RANGE_YEAR_MAX : to.to_i + buffer

          # This checks that a stored range OVERLAPS with range
          # specified in query. see
          # https://people.apache.org/~hossman/spatial-for-non-spatial-meetup-20130117/
          blacklight_params['manuscript_date'] = "[\"#{DATE_RANGE_YEAR_MIN} #{from}\" TO \"#{to} #{DATE_RANGE_YEAR_MAX}\"]"
        end
      end
    end
  end

end
