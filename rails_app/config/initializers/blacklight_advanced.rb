
#
# various overrides for blacklight here
#

Rails.application.config.to_prepare do
  # Override ClausePresenter#remove_href to also strip raw date params
  # when removing a date clause. Date fields exist as both clause params
  # (for constraint display) and raw params (for SearchBuilder date processors).
  # Without this, removing a date constraint leaves the raw param in the URL,
  # causing the RedirectLegacyParamsFilter to recreate the clause.
  Blacklight::ClausePresenter.class_eval do
    def remove_href(path = search_state)
      new_state = path.reset_search(clause: path.clause_params.except(key))

      cleaned = new_state.to_h
      SDBMSS::DATE_FIELDS.each { |f| cleaned.delete(f) }
      view_context.search_action_path(cleaned)
    end
  end

  # OVERRIDE Blacklight 9.0.0: append ?search_field=all_fields to the
  # Start Over URL so it doesn't return to the bare root page.
  Blacklight::StartOverButtonComponent.class_eval do
    def call
      link_to t('blacklight.search.start_over'),
              start_over_path + "?search_field=all_fields",
              class: 'catalog_startOverLink btn btn-primary'
    end
  end
end

# Override BAS 8.0 QueryParser#process_query to handle custom operators
# (blank, not blank, less than, greater than, without, does not contain)
# that the SDBMSS advanced search form uses.
module BlacklightAdvancedSearch
  class QueryParser
    def to_solr
      query = process_query(config)
      query.present? ? { q: query } : {}
    end

    def process_query(config)
      queries = keyword_queries.map do |clause|
        field = clause[:field]
        query = clause[:query]
        option = clause[:op]

        parsed = ParsingNesting::Tree.parse(query, config.advanced_search[:query_parser]).to_query(local_param_hash(field, config))

        process_query_option(field, query, parsed, option)
      rescue StandardError
        nil
      end.compact

      queries.join(" #{keyword_op} ")
    end

    def keyword_queries
      search_state.clause_params.values.select do |clause|
        next false if SDBMSS::DATE_FIELDS.include?(clause[:field])
        clause[:query].present? || %w[blank not\ blank].include?(clause[:op])
      end
    end

    private

    def process_query_option(field, value, query, option)
      case option
      when "with", "contains", nil
        query
      when "without", "does not contain"
        "!#{query}"
      when "blank"
        "!_query_:\"{!edismax qf=#{field}}[* TO *]\""
      when "not blank"
        "_query_:\"{!edismax qf=#{field}}[* TO *]\""
      when "less than"
        "_query_:\"{!edismax qf=#{field}}[* TO #{value}]\""
      when "greater than"
        "_query_:\"{!edismax qf=#{field}}[#{value} TO *]\""
      else
        query
      end
    end
  end
end
