class RepliesController < ApplicationController
  def create
    @reply = Reply.new(replies_params)
    @reply.save_by(current_user)
    if @reply.comment.created_by != current_user
      @reply.comment.created_by.notify(
        "#{current_user.to_s} has replied to one of your comments.",
        @reply,
        "reply"
      )
    end
    redirect_to polymorphic_path(@reply.comment.commentable)
  end

  def show
    @reply = Reply.find(params[:id])
    redirect_to polymorphic_path(@reply.comment.commentable)
  end

  def destroy
    @reply = Reply.find(params[:id])
    @reply.update(deleted: true)
    redirect_to polymorphic_path(@reply.comment.commentable)
  end

  def update
    @reply = Reply.find(params[:id])
    @reply.update(replies_params)
    redirect_to polymorphic_path(@reply.comment.commentable)
  end

  private

  def replies_params
    params.permit(:comment_id, :reply)
  end
end