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

  def create
    entry_manuscripts = params[:entry_manuscripts]
    entry_manuscripts_attributes = entry_manuscripts.map do |entry_manuscript_params|
      entry_manuscript_params.permit(:entry_id, :relation_type)
    end

    begin
      ActiveRecord::Base.transaction do
        @manuscript = Manuscript.new
        result = @manuscript.save_by(current_user)
        if result
          @manuscript.update_attributes!(
            {
              entry_manuscripts_attributes: entry_manuscripts_attributes,
            }
          )
        end
      end
    rescue Exception => e
    end

    respond_to do |format|
      format.json {
        render json: { manuscript_id: @manuscript.id }, status: :ok
      }
    end
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

end
