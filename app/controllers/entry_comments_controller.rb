
class EntryCommentsController < ApplicationController

  before_action :authenticate_user!, only: [:create]

  respond_to :html, :json

  def create
    @entry_comment = EntryComment.new(entry_comment_params)
    @entry_comment.comment.created_by_id = current_user.id
    success = @entry_comment.save
    respond_to do |format|
      format.json {
        if success
          render :json => {}, :status => :ok
        else
          json_response = { errors: @entry_comment.errors.messages }
          render json: json_response, status: :unprocessable_entity
        end
      }
    end
  end

  private

  def entry_comment_params
    params.require(:entry_comment).permit(:entry_id, :comment_attributes => [ :comment,  :public, :is_correction ])
  end

end
