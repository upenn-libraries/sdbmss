class NotificationsController < ApplicationController
  def index
    @unread = current_user.notifications.select { |n| n.active }
    @read = current_user.notifications.select { |n| !n.active }
    @unread.each { |u| u.update(active: false) }
  end
end