# Custom constraint rendering helpers for SDBMSS.
# Replaces the old BlacklightAdvancedSearch::RenderConstraintsOverride.
module SdbmssConstraintsHelper
  def render_constraints_filters_side(localized_params = params)
    return "".html_safe unless localized_params[:f]
    content = []
    localized_params[:f].each_pair do |facet, values|
      content << render_filter_element_side(facet, values, localized_params)
    end
    safe_join(content.flatten, "\n")
  end

  def render_filter_element_side(facet, values, localized_params)
    facet_config = facet_configuration_for_field(facet)

    safe_join(values.map do |val|
      next if val.blank?
      content_tag(:li, class: "facet-values list-unstyled appliedFilter") do
        content_tag(:span, class: "facet-label") do
          content_tag(:span, facet_field_label(facet_config.key), class: "filterName selected") +
          content_tag(:span, facet_config.item_presenter.new(val, facet_config, self, facet).label, class: "selected")
        end +
        link_to(
          content_tag(:i, '', class: "fa fa-times") + content_tag(:span, '[remove]', class: 'sr-only'),
          search_action_path(search_state.filter(facet).remove(val).params),
          class: "remove facet-count"
        )
      end
    end, "\n")
  end
end
