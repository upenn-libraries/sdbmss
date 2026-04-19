# TODO: Replace with Blacklight::AdvancedSearchFormComponent (BL8 native).
#   See projectblacklight/blacklight#2753 for upstream implementation.
#   Requires extending the component for SDBMSS custom operators
#   (blank, not blank, less than, greater than, without, does not contain),
#   numeric range fields, and split text/numeric columns.
#
# These helpers were in BlacklightAdvancedSearch::AdvancedHelperBehavior (BAS 7),
# removed in BAS 8.0 PR projectblacklight/blacklight_advanced_search#118.
# Reimplemented here for the custom advanced search form.
#
# Related files:
#   app/views/catalog/advanced_search.html.erb
#   app/views/catalog/_advanced_search_form.html.erb
#   app/views/catalog/_advanced_search_fields.html.erb
#   app/views/catalog/_advanced_search_help.html.erb
#   app/views/catalog/_advanced_search_submit_btns.html.erb
#   config/locales/blacklight_advanced_search.en.yml
module SdbmssAdvancedSearchHelper
  def select_menu_for_field_operator
    options = {
      t('blacklight_advanced_search.all') => 'must',
      t('blacklight_advanced_search.any') => 'should'
    }.sort
    select_tag(:op, options_for_select(options, params[:op]), class: 'input-small')
  end

  def advanced_search_context
    my_params = search_state.params_for_search.except :page, :f_inclusive, :q, :search_field, :op, :index, :sort, :clause
    my_params.except!(*search_fields_for_advanced_search.map { |_key, field_def| field_def[:key] })
    my_params
  end

  def search_fields_for_advanced_search
    @search_fields_for_advanced_search ||= begin
      blacklight_config.search_fields.select { |_k, v| v.include_in_advanced_search || v.include_in_advanced_search.nil? }
    end
  end
end
