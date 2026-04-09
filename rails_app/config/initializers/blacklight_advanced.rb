
#
# various overrides for blacklight here
#

# partially successful attempt to allow blacklight facet sorting with asc/desc option
#
# of course, it doesn't work because SOLR itself doesn't support this
# - a possible solution would be to figure out a way of loading ALL facets, then select the last X and continue normally
# - memory issues for large facet list (authors has like 5000, I think?)

# Override BL7's Catalog#facet to render not_found instead of raising
# RoutingError when a facet field doesn't exist in the config.
# (BL7 default raises ActionController::RoutingError, 'Not Found')
Rails.application.config.to_prepare do
  SearchHistoryController.helper BlacklightAdvancedSearch::RenderConstraintsOverride

  Blacklight::Catalog.module_eval do
    def facet
      @facet = blacklight_config.facet_fields[params[:id]]
      if @facet
        @response = search_service.facet_field_response(@facet.key)
        @display_facet = @response.aggregations[@facet.field]
        @pagination = facet_paginator(@facet, @display_facet)
        respond_to do |format|
          format.html do
            # Draw the partial for the "more" facet modal window:
            return render layout: false if request.xhr?
            # Otherwise draw the facet selector for users who have javascript disabled.
          end
          format.json
        end
      else
        respond_to do |format|
          format.html { render "not_found" }
          format.json { render json: {error: "Facet could not be found."} }
        end
      end
    end
  end
end

# Customize Blacklight and Blacklight Advanced Search parser to handle multiple inputs for the same field (i.e. author[]="Cicero"&author[]="Sallust" )
module BlacklightAdvancedSearch

  module ParsingNestingParser
    def process_query(params,config)
      queries = []
      keyword_queries.each do |field,query|
        options = params.include?("#{field}_option") ? params["#{field}_option"].dup : []
        values = params.include?("#{field}") ? params["#{field}"].dup : []
        if query.kind_of? Array
          query.each do |q|
            begin
              queries << process_query_option(field, values.shift, ParsingNesting::Tree.parse(q, config.advanced_search[:query_parser]).to_query( local_param_hash(field, config) ), options.shift)
            rescue StandardError => e
              #
            end
          end
        else
          begin
            queries << process_query_option(field, values, ParsingNesting::Tree.parse(query, config.advanced_search[:query_parser]).to_query( local_param_hash(field, config) ), options.shift)
          rescue StandardError => e
            #
          end
        end
      end
      queries.join( ' ' + keyword_op + ' ')
    end

    def process_query_option(field, value, query, option)
      if option == "with" || option == "contains"
        return query
      elsif option == "without" || option == "does not contain"
        return "!#{query}"
      elsif option == "blank"
        return "!_query_:\"{!edismax qf=#{field}}[* TO *]\""
      elsif option == "not blank"
        return "_query_:\"{!edismax qf=#{field}}[* TO *]\""
      elsif option == "less than"
        return "_query_:\"{!edismax qf=#{field}}[* TO #{value}]\""
      elsif option == "greater than"
        return "_query_:\"{!edismax qf=#{field}}[#{value} TO *]\""
      else
        return query
      end
    end
  end

  module RenderConstraintsOverride

    # override default search constraints display, since we're moving facets elsewhere
    def render_constraints(localized_params = search_state.to_h)
      render_constraints_query(localized_params)
    end

    def query_has_constraints?(localized_params = params)
      if is_advanced_search? localized_params
        true
      else
        !(localized_params[:q].blank?)
      end
    end

    # ... which is what we're doing here!
    def render_constraints_filters_side(localized_params = params)
      return "".html_safe unless localized_params[:f]
      content = []
      localized_params[:f].each_pair do |facet,values|
        content << render_filter_element_side(facet, values, localized_params)
      end

      safe_join(content.flatten, "\n")
    end

    def render_filter_element_side(facet, values, localized_params)
      facet_config = facet_configuration_for_field(facet)

      safe_join(values.map do |val|
        next if val.blank? # skip empty string
        #render_constraint_element( facet_field_label(facet_config.key), facet_display_value(facet, val),
        #            :remove => search_action_path(remove_facet_params(facet, val, localized_params)),
        #            :classes => ["filter", "filter-" + facet.parameterize]
        #          )
        content_tag(:li, :class => "facet-values list-unstyled appliedFilter") do
          content_tag(:span, :class => "facet-label") do
            content_tag(:span, facet_field_label(facet_config.key), :class => "filterName selected") +
            content_tag(:span, facet_display_value(facet, val), :class => "selected")
          end +
          # remove link
          link_to(content_tag(:i, '', :class => "fa fa-times") + content_tag(:span, '[remove]', :class => 'sr-only'), search_action_path(search_state.remove_facet_params(facet, val)), :class=>"remove facet-count")
        end

      end, "\n")
    end

    # handles improved display of Advanced
    def render_constraints_query(my_params = params)
      if (advanced_query.nil? || advanced_query.keyword_queries.empty? )
        return super(my_params)
      else
        numberOfQueries = advanced_query.keyword_queries.length
        content = []
        advanced_query.keyword_queries.each_pair do |field, query|
          label = blacklight_config.search_fields[field][:label]
          if query.kind_of? Array
            numberOfQueries += (query.length - 1)
            query.each do |q|
              content << render_constraint_element(label, q, :remove =>  search_action_path(remove_advanced_multiple_keyword_query(field, q, my_params)))
            end
          else
            content << render_constraint_element(
              label, query,
              :remove =>
                 search_action_path(remove_advanced_keyword_query(field,my_params))
            )
          end
        end
        if (advanced_query.keyword_op == "OR" &&
            numberOfQueries > 1)
          content.unshift content_tag(:span, "Any of:", class:'operator')
          content_tag :span, class: "inclusive_or appliedFilter card card-body bg-light" do
            safe_join(content.flatten, "\n")
          end
        else
          safe_join(content.flatten, "\n")
        end
      end
    end

    def remove_advanced_multiple_keyword_query(field, query, params)
      my_p = params.dup
      my_p[field] =  my_p[field] - [query]
      my_p.delete("controller")
      return my_p
    end

    def render_search_to_s_q(my_params)
      content = super(my_params)

      advanced_query = BlacklightAdvancedSearch::QueryParser.new(my_params, blacklight_config )

      if (advanced_query.keyword_queries.length > 1 &&
          advanced_query.keyword_op == "OR")
          # Need to do something to make the inclusive-or search clear

          display_as = advanced_query.keyword_queries.collect do |field, query|
            field = blacklight_config.search_fields[field][:label]
            if query.kind_of? Array
              query = query.join(', ')
            end
            h( field + ": " + query )
          end.join(" ; ")

          content << render_search_to_s_element("Any of",
            display_as,
            :escape_value => false
          )
      elsif (advanced_query.keyword_queries.length > 0)
        advanced_query.keyword_queries.each_pair do |field, query|
          label = blacklight_config.search_fields[field][:label]

          content << render_search_to_s_element(label, " #{Array(query).join(', ')}  ")
        end
      end
      content.prepend "#{advanced_query.keyword_op == 'OR' ? 'Any of: ' : 'All of: '}"
      return content
    end

  end
end
