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

  def create
    @comment = Comment.new(comment_params)
    @comment.save_by(current_user)
    if @comment.commentable.created_by != current_user
      @comment.commentable.created_by.notify("#{current_user.username} has commented on #{@comment.commentable.public_id}", "comment")
    end
    redirect_to polymorphic_path(@comment.commentable) + "#comment_#{@comment.id}"
  end

  def update
    @comment = Comment.find(params[:id])
    @comment.update_by(current_user, comment_params)
    redirect_to polymorphic_path(@comment.commentable) + "#comment_#{@comment.id}"
  end

  def show
    @comment = Comment.find(params[:id])
    redirect_to polymorphic_path(@comment.commentable, anchor: "comment_#{@comment.id}")
  end

  def edit
    @comment = Comment.find(params[:id])
    redirect_to polymorphic_path(@comment.commentable) + "#comment_#{@comment.id}"
  end

  private

  def comment_params
    params.permit(:commentable_id, :commentable_type, :comment)
  end

  def model_params
    puts 'comment.rb: deprecated'
    params.require(model_class_lstr.to_sym).permit(
      :comment, :is_correction, :is_accepted,
      :entry_comments_attributes => [ :id, :entry_id ],
      :manuscript_comments_attributes => [ :manuscript_id ],
      :source_comments_attributes => [ :source_id ],
      :name_comments_attributes => [ :name_id ]
    )
  end

end
