class NotificationsController < ApplicationController
  def index
    @page = params[:page].to_i || 0
    @pages = (current_user.notifications.count / 20.0).ceil
    @total = current_user.notifications.count
    @unread = current_user.notifications.where(active: true).count
    @notifications = current_user.notifications.offset(@page * 20).limit(20).order("id DESC")
  end

  def update
    @notification = Notification.find(params[:id])
    success = @notification.update!(notification_params)

    respond_to do |format|
      format.json {
        if success
          render json: {success: true}
        else
          render json: {error: "Problem updating notification!"}
        end
      }
      format.html { redirect_to notifications_path }
    end
  end

  def show
  end

  def read_many
    @notifications = Notification.where(id: params[:ids])
    @notifications.update_all(active: false)
    redirect_to notifications_path(page: params[:page])
  end

  def delete_many
    @notifications = Notification.where(id: params[:ids])
    @notifications.destroy_all
    redirect_to notifications_path(page: params[:page])
  end

  def destroy
    @notification = Notification.find(params[:id])
    @notification.destroy
    redirect_to notifications_path
  end

  private

  def notification_params
    params.permit(:id, :active)
  end
end