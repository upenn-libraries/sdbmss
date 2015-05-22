
class CommentsController < SimpleNamedModelsController

  include MarkAsReviewed

  load_and_authorize_resource :only => [:edit, :update, :destroy, :mark_as_reviewed]

  def model_class
    Comment
  end

  def search_query_base
    query = super
    query.with_associations
  end

  def search_name_field
    "comment"
  end

  def search_result_format(obj)
    {
      id: obj.id,
      entry_id: obj.entry.try(:id),
      manuscript_id: obj.manuscript.try(:id),
      comment: obj.comment,
      is_correction: obj.is_correction,
      reviewed: obj.reviewed,
      created_by: obj.created_by.username,
    }
  end

  private

  def model_params
    params.require(model_class_lstr.to_sym).permit(:comment, :is_correction)
  end

end
