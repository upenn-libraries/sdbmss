# OVERRIDE Blacklight 9.0.0 to use SDBMSS specific advanced search button
#   and to not show any of the search field dropdown options

module SDBMSS
  class SearchBarComponent < ::Blacklight::SearchBarComponent
    def advanced_search_enabled?
      false
    end

    def search_fields
      [['All Fields', 'all_fields']]
    end
  end
end
