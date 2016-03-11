class ManuscriptsController < ManageModelsController

  include MarkAsReviewed
  include LogActivity

  before_action :set_manuscript, only: [:show, :edit, :entry_candidates, :citation]

  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy]

  load_and_authorize_resource :only => [:edit, :update, :destroy, :mark_as_reviewed]

  def model_class
    Manuscript
  end

  def show
    @manuscript_comment = ManuscriptComment.new(manuscript: @manuscript)
    @manuscript_comment.build_comment
  end

  def entry_candidates
    @candidate_ids = @manuscript.entry_candidates
    respond_to do |format|
      format.json
    end
  end

  def search_result_format(obj)
    {
      id: obj.id,
      name: obj.name,
      location: obj.location,
      entries_count: obj.entries_count,
      reviewed: obj.reviewed,
      created_by: obj.created_by.present? ? obj.created_by.username : "(none)",
      created_at: obj.created_at.present? ? obj.created_at.to_formatted_s(:short) : "",
      updated_by: obj.updated_by.present? ? obj.updated_by.username : "(none)",
      updated_at: obj.updated_at.present? ? obj.updated_at.to_formatted_s(:short) : ""
    }
  end

  def citation
    respond_to do |format|
      format.js
    end
  end

  private

  def set_manuscript
    @manuscript = Manuscript.find(params[:id])
  end

  def model_params
    params.require(model_class_lstr.to_sym).permit(
      :name, :location,
      :entry_manuscripts_attributes => [ :id, :manuscript_id, :entry_id, :relation_type, :_destroy ]
    )
  end

end
