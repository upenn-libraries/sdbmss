class NamesController < SimpleNamedModelsController
  include ResourceSearch

  before_action :set_name, only: [:show, :show_json, :edit, :update, :destroy]

  def model_class
    Name
  end

  def search_results_keys
    [:id, :name, :is_artist, :is_author, :is_provenance_agent, :is_scribe]
  end

  def search_query
    query = super
    if params[:type].present?
      query = query.where(params[:type].to_sym => true)
    end
    query
  end

  def suggest
    name = params[:name]

    suggestions = Name.suggestions(name)

    respond_to do |format|
      format.json { render :json => suggestions, :status => :ok }
    end
  end

  private

  def set_name
    @name = Name.find(params[:id])
  end

  def model_params
    # wrapped parameters don't work when class name is the same as one
    # of the fields. BUT Rails' HTML form helpers send URL parameters
    # in a format that Rails WILL translate into a wrapped format. So
    # we have to account for both cases, which is this grossness here.

    # if 'name' contains something other than a string, treat it as wrapped parameters
    if params[:name].present? && !params[:name].is_a?(String)
      p = params.require(:name)
    else
      p = params
    end
    p.permit(:name, :viaf_id, :is_artist, :is_author, :is_provenance_agent, :is_scribe)
  end

end
