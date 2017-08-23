class RatingsController < ApplicationController

  load_and_authorize_resource :only => [:update, :destroy, :create]

  def create
    r = Rating.new(ratings_params)
    r.user = current_user
    r.save!
    r.ratable.index
    button_html = (render_to_string partial: "delete", locals: {rating: r }, layout: false)
    respond_to do |format|
      format.json {
        render json: { success: 'success', status_code: '200', button: button_html }
      }
      format.html {
        redirect_to polymorphic_path(r.ratable)
      }
    end
  end

  def destroy
    r = Rating.find(params[:id])
    r.destroy!
    r.ratable.index

    button_html = (render_to_string partial: "create", locals: {ratable: r.ratable }, layout: false)
    respond_to do |format|
      format.json {
        render json: { success: 'success', status_code: '200', button: button_html }
      }
      format.html {
        redirect_to polymorphic_path(r.ratable)
      }
    end
  end

  def update
    r = Rating.find(params[:id])
    r.update!(ratings_params)
    r.ratable.index
    respond_to do |format|      
      format.html {
        redirect_to polymorphic_path(r.ratable)
      }
    end
  end

  private

  def ratings_params
    params.permit(:id, :ratable_id, :ratable_type, :qualifier, :reason)
  end
end