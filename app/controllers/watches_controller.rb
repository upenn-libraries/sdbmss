class WatchesController < ApplicationController

  def create
    w = Watch.create!(watches_params)
    button_html = (render_to_string partial: "delete", locals: {watch: w }, layout: false)
    respond_to do |format|
      format.json {
        render json: { success: 'success', status_code: '200', button: button_html }
      }
    end
  end

  def destroy
    w = Watch.find(params[:id])
    w.destroy!

    button_html = (render_to_string partial: "add", locals: {watchable: w.watched }, layout: false)
    respond_to do |format|
      format.json {
        render json: { success: 'success', status_code: '200', button: button_html }
      }
      format.html {
        flash[:success] = "You are no longer watching #{w.watched.public_id}"
        redirect_to watches_path
      }
    end
  end

  def index
    @watches = current_user.watches
  end

  private

  def watches_params
    params.permit(:id, :watched_id, :watched_type, :user_id)
  end
end