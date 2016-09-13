class RepliesController < ApplicationController
  def create
    @reply = Reply.new(replies_params)
    @reply.save_by(current_user)
    if @reply.comment.commentable.created_by != current_user
      @reply.comment.commentable.created_by.notify(
        "#{current_user.to_s} has replied to one of your comments.",
        polymorphic_url(@reply.comment.commentable),
        "#{current_user.to_s} has replied to your comment on #{@reply.comment.commentable.public_id}. <blockquote>#{@reply.reply[0..100]}...</blockquote>", 
        "reply"
      )
    end
    redirect_to polymorphic_path(@reply.comment.commentable)
  end

  private

  def replies_params
    params.permit(:comment_id, :reply)
  end
end