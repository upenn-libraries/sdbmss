
# This module contains customized subclasses of things used by
# Blacklight

module SDBMSS
  DATE_FIELDS = %w[source_date manuscript_date provenance_date].freeze
end

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
      object_id = normalize_id(object_id)
      return if object_id.nil?

      @ids_to_entries[object_id] ||= nil
    end

    # returns the model object instance for the object_id
    def get(object_id)
      object_id = normalize_id(object_id)
      return nil if object_id.nil?

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

    private

    def normalize_id(object_id)
      return nil if object_id.blank?

      object_id.to_i
    end

  end

  # Specialized response that stores an instance of a ResultSet
  class SolrResponse < Blacklight::Solr::Response
    attr_accessor :objects_resultset

  end

  # Custom SearchService that prepends "Entry " to IDs for Sunspot format.
  # Sunspot indexes records as "Entry 1234" but Blacklight routes use numeric IDs.
  class SearchService < ::Blacklight::SearchService
    private

    def fetch_one(id, extra_controller_params)
      id = "Entry #{id}"
      super(id, extra_controller_params)
    end
  end

  class ShowPresenter < ::Blacklight::ShowPresenter
    def heading
      document.model_object.public_id
    end
  end

  class SearchBuilder < Blacklight::SearchBuilder
    include Blacklight::Solr::SearchBuilderBehavior
    include BlacklightAdvancedSearch::AdvancedSearchBuilder

    self.default_processor_chain += [
      :add_advanced_parse_q_to_solr,
      :add_advanced_search_to_solr,
      :show_all_if_no_query,
      :handle_facet_prefix,
      :show_approved,
      :show_created_by_user,
      :show_deprecated,
      :show_drafts,
      :translate_manuscript_date,
      :translate_provenance_date,
      :translate_source_date,
      :add_date_fields_to_solr,
      :fix_lucene_local_params,
    ]

    def show_all_if_no_query(solr_parameters)
      # edismax itself doesn't understand '*' but we can pass in q.alt
      # and it will work for some reason
      solr_parameters['q.alt'] = "*:*" if blacklight_params['q'].blank?
    end

    def show_approved(solr_parameters)
      # unless a query is specifically filtering on approved field,
      # only show approved records.
      if blacklight_params['approved'].blank?
        (solr_parameters['fq'] ||= []) << 'approved:*'
      end
    end

    def show_created_by_user(solr_parameters)
      if blacklight_params['created_by_user'].to_s == '1' && scope.current_user
        # scope is the Blacklight-configured rails controller
        (solr_parameters['fq'] ||= []) << 'created_by:' + scope.current_user.username.to_s
      end
    end

    def show_deprecated(solr_parameters)
      # unless a query is specifically filtering on approved field,
      # only show approved records.
      if blacklight_params['deprecated'].blank?
        (solr_parameters['fq'] ||= []) << 'deprecated:false'
      end
    end

    def show_drafts(solr_parameters)
      (solr_parameters['fq'] ||= []) << 'draft:false'
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
        return date if date.include?('"')

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
        return date if date.end_with?('*')

        date = date.gsub("-", "")
        short = [8 - date.length, 0].max
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

    # BAS 8 no longer builds Solr queries from raw params (only clause_params).
    # Date fields stay as raw params for the translate_* processors above.
    # This processor takes the translated date values and adds them to the Solr query.
    def add_date_fields_to_solr(solr_parameters)
      SDBMSS::DATE_FIELDS.each do |field_name|
        value = blacklight_params[field_name]
        next if value.blank?

        field_def = blacklight_config.search_fields[field_name] || {}
        solr_field = field_def.dig(:solr_parameters, :qf) || field_name

        Array(value).reject(&:blank?).each do |v|
          (solr_parameters['fq'] ||= []) << "#{solr_field}:#{v}"
        end
      end
    end

    def translate_source_date(solr_parameters)
      translate_date_to_search_query(solr_parameters, 'source_date')
    end

    def translate_manuscript_date(solr_parameters)
      translate_daterange_param(solr_parameters, 'manuscript_date', DATE_RANGE_YEAR_MIN, DATE_RANGE_YEAR_MAX)
    end

    def translate_provenance_date(solr_parameters)
      translate_daterange_param(solr_parameters, 'provenance_date', DATE_RANGE_FULL_MIN, DATE_RANGE_FULL_MAX)
    end

    # Solr 8: {!lucene} local params in q are ignored when defType=edismax
    # is set as a request parameter. Remove defType so local params take effect.
    def fix_lucene_local_params(solr_parameters)
      if solr_parameters[:q].to_s.start_with?('{!lucene}')
        solr_parameters.delete(:defType)
      end
    end
  end

end
