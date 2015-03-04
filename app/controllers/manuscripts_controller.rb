class ManuscriptsController < SimpleNamedModelsController

  before_action :set_manuscript, only: [:show, :edit, :entry_candidates]

  def model_class
    Manuscript
  end

  def entry_candidates
    @candidate_ids = @manuscript.entry_candidates
    respond_to do |format|
      format.json
    end
  end

  def search_results_keys
    [:id, :name, :entries_count]
  end

  private

  def set_manuscript
    @manuscript = Manuscript.find(params[:id])
  end

end
