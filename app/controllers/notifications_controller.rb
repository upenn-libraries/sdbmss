class NotificationsController < ApplicationController
  def index
    @notifications = current_user.notifications
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
    end
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