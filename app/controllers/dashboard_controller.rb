class DashboardController < ApplicationController

  before_action :authenticate_user!

  def show
    # compiles activity on the records you are watching - is there an easier way of doing this?
    @activities = (Activity.where(item: current_user.watched_sources).order("created_at desc").limit(10) +
          Activity.where(item: current_user.watched_manuscripts).order("created_at desc").limit(10) +
          Activity.where(item: current_user.watched_names).order("created_at desc").limit(10) +
          Activity.where(item: current_user.watched_entries).order("created_at desc").limit(10)).sort { |a, b| b.created_at <=> a.created_at }.first(10)
    @unread = current_user.notifications.select { |n| n.active }
    @read = current_user.notifications.select { |n| !n.active }
  end

end
