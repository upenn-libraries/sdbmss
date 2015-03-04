class NamesController < SimpleNamedModelsController
  include ResourceSearch

  before_action :set_name, only: [:show, :show_json, :edit, :update, :destroy]

  def model_class
    Name
  end

  def create
    @name = Name.new(name_params)
    @name.save!
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

  private

  def set_name
    @name = Name.find(params[:id])
  end

  def name_params
    # we don't use wrapped parameters here b/c Rails won't wrap if
    # fieldname is same as class
    params.permit(:name, :is_artist, :is_author, :is_provenance_agent, :is_scribe)
  end

end
