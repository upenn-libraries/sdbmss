# frozen_string_literal: true

##
# Override Blacklight::Catalog#facet behavior to add error handling when
# there is no facet.
module CustomFacet
  extend ActiveSupport::Concern

  def facet
    @facet = blacklight_config.facet_fields[params[:id]]
    if @facet
      @response = get_facet_field_response(@facet.key, params)
      @display_facet = @response.aggregations[@facet.key]

      @pagination = facet_paginator(@facet, @display_facet)

      respond_to do |format|
        # Draw the facet selector for users who have javascript disabled:
        format.html
        format.json { render json: render_facet_list_as_json }

        # Draw the partial for the "more" facet modal window:
        format.js { render :layout => false }
      end
    else
      respond_to do |format|
        format.html { render "not_found" }
        format.json { render json: { error: "Facet could not be found." } }
        format.js { render json: { error: "Facet could not be found." } }
      end
    end
  end
end
