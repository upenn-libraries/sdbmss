# Customize the Blacklight Advanced Search parser to handle multiple inputs for the same field (i.e. author[]="Cicero"&author[]="Sallust" )

puts BlacklightAdvancedSearch, BlacklightAdvancedSearch::ParsingNestingParser

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
    def self.is_adding
      puts "no!?"
    end
  end
end