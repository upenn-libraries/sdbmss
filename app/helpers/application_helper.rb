module ApplicationHelper

  def format_fuzzy_date(d)
    SDBMSS::Util.format_fuzzy_date(d)
  end

  # returns a URL for a new search on a given facet and value. This
  # should probably ONLY be used for Names. Links for other searches
  # should use #search_advanced_path.
  def search_by_facet_value facet_name, value
    # call helpers from BlacklightUrlHelper
    sdbmss_search_action_path(add_facet_params(facet_name, value, {}))
  end

  # returns a URL for an advanced search; options is a hash that
  # should contain a key corresponding to a field name, hashed to a
  # search value
  def search_advanced_path(options)
    sdbmss_search_action_path({ "utf8" => SDBMSS::Util::CHECKMARK, "op" => "AND", "search_field" => "advanced", "commit" => "Search" }.merge(options))
  end

  # this just takes you to a blank search, which shows you all entries ordered by most recent
  def recent_additions_path
    # don't use search_action_path here; it gets redefined by advanced
    # search controller, breaking the link on that page
    root_path({ "utf8" => SDBMSS::Util::CHECKMARK, "search_field" => "all_fields", "q" => "" })
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
    new_params = @pagination.params_for_resort_url('index', params)
    if prefix != 'all'
      new_params["prefix"] = prefix
    else
      # 'all' should clear prefix
      new_params.delete "prefix"
    end
    new_params
  end

  # overrides Blacklight::BlacklightHelperBehavior#render_bookmarks_control?
  def render_bookmarks_control?
    user_signed_in?
  end

  # overrides Blacklight::BlacklightHelperBehavior#render_saved_searches?
  def render_saved_searches?
    user_signed_in?
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

  def show_linking_tool_by_entry?
    user_signed_in? && @document.present? && (entry = @document.model_object).present? && !entry.manuscript.present? && can?(:link, entry) && !entry.deprecated
  end

  def show_linking_tool_by_manuscript?
    user_signed_in? && @document.present? && (entry = @document.model_object).present? && entry.manuscript.present? && can?(:link, entry.manuscript)
  end

  def show_deprecate_entry?
    user_signed_in? && @document.present? && (entry = @document.model_object).present? && can?(:deprecate, entry)
  end

  # determines whether entry history link should be displayed; this is
  # used multiple places, which is why it's here in ApplicationHelper
  def show_entry_history_link?
    # @document.present? && (entry = @document.model_object).present? && entry.versions.count > 0 && can?(:link, entry)
    user_signed_in? && @document.present? && (entry = @document.model_object).present?
  end

  # only show on Bookmarks page (check for document_list)
  def show_export_csv_link?
    user_signed_in? && @document_list.present?
  end

  # this method returns a data structure used to prepopulate the
  # advanced search form.
  def prepopulated_search_fields_for_advanced_search(num_fields, is_numeric: true)
    # get all the search fields defined in Blacklight config, as a
    # Hash of string field names to Field objects
    fields = search_fields_for_advanced_search.select { |key, field_def|
      is_numeric ? field_def.is_numeric_field : !field_def.is_numeric_field
    }

    # create an array of just the string field names
    fieldnames = fields.keys

    # figure out, from #params, the 'simple search' that user did
    queried_fields = params.dup
    if queried_fields["search_field"].present?
      queried_fields[queried_fields["search_field"]] = queried_fields["q"]
    end
    queried_fields = queried_fields.select { |k,v| fieldnames.member? k }
    queried_fields.sort

    # now make an Array of OpenStructs for each row corresponding to a
    # set of form inputs, for advanced search page
    num_fields.times.map do |i|
      selected_field, value, value2 = nil, nil, nil
      if queried_fields.length > 0
        fieldname = queried_fields.keys.first
        selected_field = fieldname

        if !fields[fieldname].is_numeric_field
          value = queried_fields[fieldname]
        else
          range_str = queried_fields[fieldname]
          match = /\[(\d+)\s+TO\s+(\d+)\]/.match(range_str)
          if match
            value, value2 = match[1], match[2]
          end
        end
        queried_fields.delete(fieldname)
      end
      OpenStruct.new(
        index: i,
        fields: fields,
        selected_field: selected_field,
        value: value,
        value2: value2,
      )
    end
  end

  def render_partial_if_exists(path_to_partial, fall_through, *args)
    if lookup_context.template_exists?(path_to_partial, [], true)
      args[0][:partial] = path_to_partial
    else
      args[0][:partial] = fall_through
    end
    render(*args)
  end

end
