
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

    def show_approved(solr_parameters)
      # unless a query is specifically filtering on approved field,
      # only show approved records.
      if blacklight_params['approved'].blank?
        solr_parameters['fq'] << 'approved:true'
      end
    end

    def show_created_by_user(solr_parameters)
      if blacklight_params['created_by_user'].to_s == '1'
        # scope is the Blacklight-configured rails controller
        solr_parameters['fq'] << 'created_by:' + scope.current_user.username.to_s
      end
    end

    def show_deprecated(solr_parameters)
      # unless a query is specifically filtering on approved field,
      # only show approved records.
      if blacklight_params['deprecated'].blank?
        solr_parameters['fq'] << 'deprecated:false'
      end
    end

    def handle_facet_prefix(solr_parameters)
      if blacklight_params[:prefix].present?
        # 'id' key probably comes from routing setup internal to Blacklight
        solr_parameters[:"f.#{blacklight_params[:id]}.facet.prefix"] = blacklight_params[:prefix]
      end
    end

    # This translates a query str of "[year1 TO year2]" in the date
    # range parameter field to a str of the form '["minX minY" TO
    # "maxX maxY"]'. We do this translation so that BL params are kept
    # readable and front-end JS can treat date range queries exactly
    # the same as other numeric range queries.
    def translate_daterange_string(date, min, max)
      if date.present?
        m = /\[(.+?) TO (.+?)\]/.match(date)
        if m
          from, to = m[1], m[2]

          # buffer the dates so that we don't pick up end dates
          # themselves (ranges are end-exclusive)
          buffer = 0.5
          from = from == '*' ? min : from.to_i + buffer
          to = to == '*' ? max : to.to_i + buffer

          # This checks that a stored range OVERLAPS with range
          # specified in query. see
          # https://people.apache.org/~hossman/spatial-for-non-spatial-meetup-20130117/
          return "[\"#{min} #{from}\" TO \"#{to} #{max}\"]"
        else
          return translate_date_string_to_search_query(date)
        end
      end
    end

    def translate_daterange_param(solr_parameters, param_name, min, max)
      date = blacklight_params[param_name]
      if date.kind_of? Array
        result = []
        date.each do |d|
          result += [translate_daterange_string(d, min, max)]
        end
        blacklight_params[param_name] = result
      else
        blacklight_params[param_name] = translate_daterange_string(date, min, max)
      end
    end

    def translate_date_string_to_search_query(date)
      if date.present?
        date = date.gsub("-", "")
        short = 8 - date.length
        date = date + "*" * short
        return date
      end
    end

    def translate_date_to_search_query(solr_parameters, param_name)
      date = blacklight_params[param_name]
      if date.kind_of? Array
        result = []
        date.each do |d|
          result += [translate_date_string_to_search_query(d)]
        end
        blacklight_params[param_name] = result
      else
        blacklight_params[param_name] = translate_date_string_to_search_query(date)
      end
    end

    def translate_source_date(solr_parameters)
      translate_date_to_search_query(solr_parameters, 'source_date')
    end

    # FIX ME: should these be 'translated'?  Or just searched as strings

    def translate_manuscript_date(solr_parameters)
      translate_daterange_param(solr_parameters, 'manuscript_date', DATE_RANGE_YEAR_MIN, DATE_RANGE_YEAR_MAX)
    end

    def translate_provenance_date(solr_parameters)
      translate_daterange_param(solr_parameters, 'provenance_date', DATE_RANGE_FULL_MIN, DATE_RANGE_FULL_MAX)
    end
  end

end
