class RatingsController < ApplicationController

  def create
    r = Rating.create!(ratings_params)
    button_html = (render_to_string partial: "delete", locals: {rating: r }, layout: false)
    respond_to do |format|
      format.json {
        render json: { success: 'success', status_code: '200', button: button_html }
      }
    end
  end

  def destroy
    r = Rating.find(params[:id])
    r.destroy!

    button_html = (render_to_string partial: "create", locals: {ratable: r.ratable }, layout: false)
    respond_to do |format|
      format.json {
        render json: { success: 'success', status_code: '200', button: button_html }
      }
      format.html {
        flash[:success] = "You are no longer watching #{w.watched.public_id}"
        redirect_to root_path
      }
    end
  end

  private

  def ratings_params
    params.permit(:id, :ratable_id, :ratable_type, :user_id, :user_level)
  end
end