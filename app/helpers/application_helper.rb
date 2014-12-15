module ApplicationHelper

  def format_fuzzy_date(d)
    SDBMSS::Util.format_fuzzy_date(d)
  end

  # returns a URL for a new search on a given facet and value
  def search_by_facet_value facet_name, value
    search_action_path(add_facet_params(facet_name, value, {}))
  end

end
