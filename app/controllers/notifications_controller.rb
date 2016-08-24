class NotificationsController < ApplicationController
  def index
    @unread = current_user.notifications.select { |n| n.active }
    @read = current_user.notifications.select { |n| !n.active }
    @unread.each { |u| u.update(active: false) }
  end

  def destroy
    @notification = Notification.find(params[:id])
    @notification.destroy
    redirect_to notifications_path
  end
end