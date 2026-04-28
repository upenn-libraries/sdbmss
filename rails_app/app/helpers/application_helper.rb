require 'ostruct'

module ApplicationHelper

  def format_fuzzy_date(d)
    SDBMSS::Util.format_fuzzy_date(d)
  end

  # returns a URL for a new search on a given facet and value. This
  # should probably ONLY be used for Names. Links for other searches
  # should use #search_advanced_path.
  def search_by_facet_value facet_name, value
    # call helpers from BlacklightUrlHelper
    sdbmss_search_action_path(controller.search_state_class.new({}, blacklight_config, controller).filter(facet_name).add(value).params)
  end

  # returns a URL for an advanced search; options is a hash that
  # should contain a key corresponding to a field name, hashed to a
  # search value
  def search_advanced_path(options)
    sdbmss_search_action_path({ "op" => "AND", "search_field" => "advanced" }.merge(options))
  end

  # this just takes you to a blank search, which shows you all entries ordered by most recent
  def recent_additions_path
    # don't use search_action_path here; it gets redefined by advanced
    # search controller, breaking the link on that page
    # recent additions: right now shows additions in LAST month only
    #sdbmss_search_action_path({ "utf8" => SDBMSS::Util::CHECKMARK, "commit" => "Search", "op" => "OR"})
    sdbmss_search_action_path({ "op" => "OR", "added_on" => [Date.today.prev_month.strftime("%Y-%m*"), Date.today.strftime("%Y-%m*")], "search_field" => "advanced"})
#    root_path({ "utf8" => SDBMSS::Util::CHECKMARK, "q" => Date.today.prev_month.strftime("%Y-%m*"), "search_field" => "created_at" })
#    root_path({ "utf8" => SDBMSS::Util::CHECKMARK, "search_field" => "all_fields", "q" => "" })
  end

  # returns a URL to use for the data-context-href link attribute, on
  # items on the search results page. This is the mechanism that makes
  # pagination work on the individual Entry view.
  def track_path document, document_counter
    # ugly and possible fragile: call
    # Blacklight::UrlHelperBehavior#session_tracking_params, which
    # returns a nested data struct that we dig into
    struct = session_tracking_params document, document_counter_with_offset(document_counter)
    struct[:data][:"context-href"]
  end

  # for facet listing page, returns a URL for current search with prefix parameter added
  def params_for_prefix_url prefix
    if @pagination == nil
      raise "params_for_prefix_url called from view where @pagination isn't available"
    end
    new_params = @pagination.params_for_resort_url('index', search_state.to_h)
    if prefix != 'all'
      new_params["prefix"] = prefix
    else
      # 'all' should clear prefix
      new_params.delete "prefix"
    end
    new_params
  end

  # NOT overridden from blacklight
  def render_search_history_control?
    user_signed_in?
  end

  # determines whether edit entry link should be displayed; this is
  # used multiple places, which is why it's here in ApplicationHelper
  def show_edit_entry_link?
    user_signed_in? && @document.present? && (entry = @document.model_object).present? && can?(:edit, entry)
  end

  # only show on Bookmarks page (check for document_list)
  def show_export_csv_link?
    user_signed_in? && @response&.documents&.present?
  end


  def render_partial_if_exists(path_to_partial, fall_through, *args)
    if lookup_context.template_exists?(path_to_partial, [], true)
      args[0][:partial] = path_to_partial
    else
      args[0][:partial] = fall_through
    end
    render(*args)
  end

  def get_date_display (first, last)
    today = Time.now.to_date
    difference = (today - first.to_date).round
    if difference <= 1
      "today"
    elsif difference <= 2
      "yesterday"
    elsif difference <= 7
      "less than one week ago"
    elsif difference <= 62
      "#{difference / 7} week(s) ago"
    elsif difference <= 365
      "#{difference / 31} month(s) ago"
    else
      "#{difference / 365} year(s) ago"
    end
  end

end
