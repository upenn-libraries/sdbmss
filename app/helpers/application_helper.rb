module ApplicationHelper

  def format_fuzzy_date(d)
    SDBMSS::Util.format_fuzzy_date(d)
  end

  # returns a URL for a new search on a given facet and value. This
  # should probably ONLY be used for Names. Links for other searches
  # should use #search_advanced_url.
  def search_by_facet_value facet_name, value
    # call helpers from BlacklightUrlHelper
    search_action_path(add_facet_params(facet_name, value, {}))
  end

  # returns a URL for an advanced search; options is a hash that
  # should contain a key corresponding to a field name, hashed to a
  # search value
  def search_advanced_url(options)
    checkmark = "\u2713".encode('utf-8')
    catalog_index_path({ "utf8" => checkmark, "op" => "AND", "search_field" => "advanced", "commit" => "Search" }.merge(options))
  end

  # returns a URL to use for the data-context-href link attribute, on
  # items on the search results page. This is the mechanism that makes
  # pagination work on the individual Entry view.
  def track_url document, document_counter
    # ugly and possible fragile: call
    # Blacklight::UrlHelperBehavior#session_tracking_params, which
    # returns a nested data struct that we dig into
    struct = session_tracking_params document, document_counter_with_offset(document_counter)
    struct[:data][:"context-href"]
  end

  # determines whether edit entry link should be displayed; this is
  # used multiple places, which is why it's here in ApplicationHelper
  def show_edit_entry_link?
    user_signed_in?
  end

  # determines whether edit ms link should be displayed; this is used
  # multiple places, which is why it's here in ApplicationHelper
  def show_edit_manuscript_link?
    return false if !user_signed_in? || !@document
    entry = @document.model_object
    entry.present? && (manuscript = entry.get_manuscript).present?
  end

  # determines whether Find or Create MS link should be displayed;
  # this is used multiple places, which is why it's here in
  # ApplicationHelper
  def show_find_or_create_manuscript_link?
    return !show_edit_manuscript_link?
  end

end
