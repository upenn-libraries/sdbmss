class CommentsController < SearchableAuthorityController

  include MarkAsReviewed
  include LogActivity

  load_and_authorize_resource :only => [:index, :edit, :update, :destroy, :mark_as_reviewed]

  def model_class
    Comment
  end

  def create
    ActiveRecord::Base.transaction do
      @comment = Comment.new(comment_params)
      @comment.save_by(current_user)
      if defined?(@comment.commentable.created_by) && @comment.commentable.created_by != current_user && @comment.commentable.created_by
        @comment.commentable.created_by.notify(
          "#{current_user.to_s} has commented on #{@comment.commentable.public_id}",
          @comment, 
          "comment"
        )
      end
      User.where(role: "admin").each do |user|
        user.notify(
          "#{current_user.to_s} has commented on #{@comment.commentable.public_id}",
          @comment, 
          "all_comment"
        )
      end
      @transaction_id = PaperTrail.transaction_id      
    end
    redirect_to polymorphic_path(@comment.commentable, anchor: "comment_#{@comment.id}")
  end

  def update
    ActiveRecord::Base.transaction do
      @comment = Comment.find(params[:id])
      @comment.update_by(current_user, comment_params)
      @transaction_id = PaperTrail.transaction_id      
    end
    redirect_to polymorphic_path(@comment.commentable) + "#comment_#{@comment.id}"
  end

  def show
    @comment = Comment.find(params[:id])
    if @comment.commentable
      redirect_to polymorphic_path(@comment.commentable, anchor: "comment_#{@comment.id}")
    else
      @comments = Comment.where(commentable_id: @comment.commentable_id, commentable_type: @comment.commentable_type)
    end
  end

  def edit
    @comment = Comment.find(params[:id])
    redirect_to polymorphic_path(@comment.commentable) + "#comment_#{@comment.id}"
  end

  def destroy
    @comment = Comment.find(params[:id])
    # mark as deleted, don't actually destroy the record
    if deletable?(@comment)
      ActiveRecord::Base.transaction do
        @comment.deleted = true
        if @comment.save
          respond_to do |format|
            format.json {
              render status: :ok, json: {}
            }
            format.html {
              redirect_to polymorphic_path(@comment.commentable)
            }
          end
        else
          respond_to do |format|
            format.json {
              render status: :unprocessable_entity, json: { "error" => @comment.errors.join("; ") }
            }
            format.html {
              flash[:error] = @comment.errors.join("; ")
              redirect_to polymorphic_path(@comment.commentable)
            }
          end
        end
        @transaction_id = PaperTrail.transaction_id      
      end
    else
      respond_to do |format|
        format.json {
          render status: :unprocessable_entity, json: { "error" => "Record is not deletable, probably because other records are associated with it" }
        }
        format.html {
          flash[:error] = "Record is not deletable, probably because other records are associated with it."
          redirect_to polymorphic_path(@comment.commentable)
        }
      end
    end
  end

  private

  def comment_params
    params.permit(:commentable_id, :commentable_type, :comment)
  end

end
