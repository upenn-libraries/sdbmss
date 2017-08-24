
# 
# various overrides for blacklight here
# 

# partially successful attempt to allow blacklight facet sorting with asc/desc option
# 
# of course, it doesn't work because SOLR itself doesn't support this
# - a possible solution would be to figure out a way of loading ALL facets, then select the last X and continue normally
# - memory issues for large facet list (authors has like 5000, I think?)

module Blacklight::Solr
  class FacetPaginator
    mattr_accessor :request_keys do
      { sort: :'facet.sort', page: :'facet.page', order: :'facet.order' }
    end

    if Rails.version < "4.1"
      self.request_keys = { sort: :'facet.sort', page: :'facet.page', order: :'facet.order' }
    end

    attr_reader :offset, :limit, :sort, :order

    def initialize(all_facet_values, arguments)
      # to_s.to_i will conveniently default to 0 if nil
      @offset = arguments[:offset].to_s.to_i 
      @limit = arguments[:limit]
      # count is solr's default
      @sort = arguments[:sort] || "count"
      @order = arguments[:order] || "desc"

      #puts "dsagfadfgafdg >>>>>>>>>>>>>>>> #{all_facet_values.inspect}"

      @all = @order == "desc" ? all_facet_values : all_facet_values.reverse
    end
  end
end

module Blacklight
  module Facet
    def facet_paginator(field_config, display_facet)
      blacklight_config.facet_paginator_class.new(
        display_facet.items,
        sort: display_facet.sort,
        offset: display_facet.offset,
        limit: facet_limit_for(field_config.key),
        order: display_facet.order
      )
    end
  end
end

# because we are using blacklight and sunspot, I have to override this method since blacklight 
# expects sunspot(solr) to index by ID as a number, but sunspot needs to index it by a string (Entry ID)
# 
# to compensate, since it's literally a string change, I just do it here...

module Blacklight::SearchHelper
  def fetch_one(id, extra_controller_params)
    old_solr_doc_params = Deprecation.silence(Blacklight::SearchHelper) do
      solr_doc_params(id)
    end

    if default_solr_doc_params(id) != old_solr_doc_params
      Deprecation.warn Blacklight::SearchHelper, "The #solr_doc_params method is deprecated. Instead, you should provide a custom SolrRepository implementation for the additional behavior you're offering. The current behavior will be removed in Blacklight 6.0"
      extra_controller_params = extra_controller_params.merge(old_solr_doc_params)
    end

    # here!
    id = "Entry #{id}"

    solr_response = repository.find id, extra_controller_params
    [solr_response, solr_response.documents.first]
  end
end

module Blacklight::Solr
  module SearchBuilderBehavior
    def add_facet_paging_to_solr(solr_params)
      return unless facet.present?

      facet_config = blacklight_config.facet_fields[facet]

      # Now override with our specific things for fetching facet values
      facet_ex = facet_config.respond_to?(:ex) ? facet_config.ex : nil
      solr_params[:"facet.field"] = with_ex_local_param(facet_ex, facet)

      limit = if scope.respond_to?(:facet_list_limit)
                scope.facet_list_limit.to_s.to_i
              elsif solr_params["facet.limit"]
                solr_params["facet.limit"].to_i
              else
                20
              end

      page = blacklight_params.fetch(request_keys[:page], 1).to_i
      offset = (page - 1) * (limit)

      sort = blacklight_params[request_keys[:sort]]

      # Need to set as f.facet_field.facet.* to make sure we
      # override any field-specific default in the solr request handler.
      solr_params[:"f.#{facet}.facet.limit"] = limit + 1
      solr_params[:"f.#{facet}.facet.offset"] = offset
      if blacklight_params[request_keys[:sort]]
        solr_params[:"f.#{facet}.facet.sort"] = sort
      end

      if blacklight_params[request_keys[:order]]
        solr_params[:"f.#{facet}.facet.order"] = blacklight_params[request_keys[:order]]
      end

      solr_params[:rows] = 0
    end  
  end
end

module Blacklight::SolrResponse::Facets
  class FacetField

    def order
      @options[:order]
    end
  end

  private

  def facet_field_aggregations
    list_as_hash(facet_fields).each_with_object({}) do |(facet_field_name, values), hash|
      items = []
      options = {}
      values.each do |value, hits|
        i = FacetItem.new(value: value, hits: hits)

        # solr facet.missing serialization
        if value.nil?
          i.label = I18n.t(:"blacklight.search.fields.facet.missing.#{facet_field_name}", default: [:"blacklight.search.facets.missing"])
          i.fq = "-#{facet_field_name}:[* TO *]"
        end

        items << i
      end
      options[:sort] = (params[:"f.#{facet_field_name}.facet.sort"] || params[:'facet.sort'])
      if params[:"f.#{facet_field_name}.facet.limit"] || params[:"facet.limit"]
        options[:limit] = (params[:"f.#{facet_field_name}.facet.limit"] || params[:"facet.limit"]).to_i
      end

      if params[:"f.#{facet_field_name}.facet.offset"] || params[:'facet.offset']
        options[:offset] = (params[:"f.#{facet_field_name}.facet.offset"] || params[:'facet.offset']).to_i
      end

      options[:order] = (params[:"f.#{facet_field_name}.facet.order"] || params[:'facet.order'])

      hash[facet_field_name] = FacetField.new(facet_field_name, items, options)

      if blacklight_config and !blacklight_config.facet_fields[facet_field_name]
        # alias all the possible blacklight config names..
        blacklight_config.facet_fields.select { |k,v| v.field == facet_field_name }.each do |key,_|
          hash[key] = hash[facet_field_name]
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
            queries << process_query_option(field, values.shift, ParsingNesting::Tree.parse(q, config.advanced_search[:query_parser]).to_query( local_param_hash(field, config) ), options.shift)
          end
        else
          queries << process_query_option(field, values, ParsingNesting::Tree.parse(query, config.advanced_search[:query_parser]).to_query( local_param_hash(field, config) ), options.shift)
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
    def render_constraints(localized_params = params)
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
          link_to(content_tag(:span, '', :class => "glyphicon glyphicon-remove") + content_tag(:span, '[remove]', :class => 'sr-only'), search_action_path(remove_facet_params(facet, val, localized_params)), :class=>"remove facet-count")
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
          label = search_field_def_for_key(field)[:label]
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
          content_tag :span, class: "inclusive_or appliedFilter well" do
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
            field = search_field_def_for_key(field)[:label]
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
          label = search_field_def_for_key(field)[:label]

          content << render_search_to_s_element(label, " #{Array(query).join(', ')}  ")
        end
      end
      content.prepend "#{advanced_query.keyword_op == 'OR' ? 'Any of: ' : 'All of: '}"
      return content
    end

  end
end