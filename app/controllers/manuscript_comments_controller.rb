
class ManuscriptCommentsController < ApplicationController

  before_action :authenticate_user!, only: [:create]

  respond_to :html, :json

  def create
    @manuscript_comment = ManuscriptComment.new(manuscript_comment_params)
    @manuscript_comment.comment.created_by_id = current_user.id
    @manuscript_comment.save
    if params[:return_url]
      redirect_to params[:return_url]
    else
      respond_with(@manuscript_comment)
    end
  end

  private

  def manuscript_comment_params
    params.require(:manuscript_comment).permit(:manuscript_id, :comment_attributes => [ :comment,  :public, :is_correction ])
  end

end
