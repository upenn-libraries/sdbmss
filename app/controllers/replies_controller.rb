class RepliesController < ApplicationController
  def create
    @reply = Reply.new(replies_params)
    @reply.save_by(current_user)
    if @reply.comment.commentable.created_by != current_user
      @reply.comment.commentable.created_by.notify("#{current_user.username} has commented on #{@reply.comment.commentable.public_id}", "reply")
    end
    redirect_to polymorphic_path(@reply.comment.commentable)
  end

  private

  def replies_params
    params.permit(:comment_id, :reply)
  end
end