# Customize the Blacklight Advanced Search parser to handle multiple inputs for the same field (i.e. author[]="Cicero"&author[]="Sallust" )

module BlacklightAdvancedSearch
  module ParsingNestingParser
    def process_query(params,config)
      queries = []
      keyword_queries.each do |field,query|
        if query.kind_of? Array
          query.each do |q|
            queries << ParsingNesting::Tree.parse(q, config.advanced_search[:query_parser]).to_query( local_param_hash(field, config) )
          end
        else
          queries << ParsingNesting::Tree.parse(query, config.advanced_search[:query_parser]).to_query( local_param_hash(field, config) )
        end
      end
      queries.join( ' ' + keyword_op + ' ')
    end
  end

  module RenderConstraintsOverride
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
              query = '[' + query.join(', ') + ']'
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

          content << render_search_to_s_element(label, query)
        end
      end

      return content
    end

  end
end