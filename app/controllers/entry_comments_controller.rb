
class EntryCommentsController < ApplicationController

  before_action :authenticate_user!, only: [:create]

  respond_to :html, :json

  def create
    @entry_comment = EntryComment.new(entry_comment_params)
    @entry_comment.comment.created_by_id = current_user.id
    @entry_comment.save
    if params[:return_url]
      redirect_to params[:return_url]
    else
      respond_with(@entry_comment)
    end
  end

  private

  def entry_comment_params
    params.require(:entry_comment).permit(:entry_id, :comment_attributes => [ :comment,  :public, :is_correction ])
  end

end
