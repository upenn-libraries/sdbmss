class WatchesController < ApplicationController

  def create
    results = {}
    watches_params[:watched].each do |watched|
      if (w = Watch.create(watched_id: watched[:id], watched_type: watched[:type], user: current_user))
        results["Watch_#{watched[:type]}_#{watched[:id]}"] = {button_html: (render_to_string partial: "delete", locals: {watch: w }, layout: false)}
      end
    end
    respond_to do |format|
      format.json {
        render json: { success: 'success', status_code: '200', results: results }
      }
    end
  end

  def destroy
    watches = Watch.where(id: params[:ids])
    watched = watches.map(&:watched)
    if watches.destroy_all
      results = watched.map { |w| ["Watch_#{w.class.name}_#{w.id}", {button_html: (render_to_string partial: "add", locals: {watchable: w }, layout: false)}]}.to_h
      respond_to do |format|
        format.json {
          render json: { success: 'success', status_code: '200', results: results, method: 'post' } 
        }
        format.html {
          flash[:notice] = "<span class='glyphicon glyphicon-eye-close'></span> #{watched.count} Records <b>Unwatched</b>".html_safe
          redirect_to watches_path          
        }
      end
    else

    end
  end

  def index
    @total = current_user.watches.count
    @page = params[:page].to_i || 0
    @per_page = 20
    @watches = current_user.watches.offset(@page * @per_page).limit(@per_page)
  end

  private

  def watches_params
    params.permit(:ids, :watched => [:id, :type])
  end
end