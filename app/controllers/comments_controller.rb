
class CommentsController < SearchableAuthorityController

  include MarkAsReviewed
  include LogActivity

  load_and_authorize_resource :only => [:edit, :update, :destroy, :mark_as_reviewed]

  def model_class
    Comment
  end

  def search_fields
    super
    @fields.unshift("comment")
    @fields.delete("name")
    @filters += ["entry", "manuscript", "source", "name"]
    @fields + @filters + @dates
  end

  def search_query_base
    query = super
    query.with_associations
  end

  def search_name_field
    "comment"
  end

  # delete this?
  def search_result_format(obj)
    {
      id: obj.id,
      entry_id: obj.entry.try(:id),
      manuscript_id: obj.manuscript.try(:id),
      source_id: obj.source.try(:id),
      comment: obj.comment,
      #is_correction: obj.is_correction,
      is_accepted: obj.is_accepted,
      reviewed: obj.reviewed,
      created_by: obj.created_by.username,
      created_at: obj.created_at.to_formatted_s(:date_and_time),
      updated_by: obj.updated_by.present? ? obj.updated_by.username : "(none)",
      updated_at: obj.updated_at.present? ? obj.updated_at.to_formatted_s(:long) : ""
    }
  end

  private

  def model_params
    params.require(model_class_lstr.to_sym).permit(
      :comment, :is_correction, :is_accepted,
      :entry_comments_attributes => [ :id, :entry_id ],
      :manuscript_comments_attributes => [ :manuscript_id ],
      :source_comments_attributes => [ :source_id ],
      :name_comments_attributes => [ :name_id ]
    )
  end

end
