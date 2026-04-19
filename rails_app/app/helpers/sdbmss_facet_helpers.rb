# BL8 helper methods for rendering facets using Blacklight::FacetComponent
# (replaces the old FacetsHelperBehavior monkey-patch that used render_facet_limit)
module SdbmssFacetHelpers
  def render_all_facet_partials
    facet_field_names = blacklight_config.facet_fields.keys
    field_configs = facet_field_names.map { |f| blacklight_config.facet_configuration_for_field(f) }
    safe_join(field_configs.map { |field_config|
      render(Blacklight::FacetComponent.new(field_config: field_config, response: @response, blacklight_config: blacklight_config))
    }.compact, "\n")
  end

  def render_facet_partials_home(number, direction)
    facet_field_names = blacklight_config.facet_fields.keys
    field_configs = facet_field_names.map { |f| blacklight_config.facet_configuration_for_field(f) }
    selected = direction == :before ? field_configs.first(number) : field_configs.last(field_configs.count - number)
    safe_join(selected.map { |field_config|
      render(Blacklight::FacetComponent.new(field_config: field_config, response: @response, blacklight_config: blacklight_config))
    }.compact, "\n")
  end
end
