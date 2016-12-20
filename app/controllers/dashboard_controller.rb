class DashboardController < ApplicationController

  before_action :authenticate_user!

  def show
    # compiles activity on the records you are watching - is there an easier way of doing this?

    if params[:mine]
      start_date = Activity.where(user: current_user).order("created_at desc").group("DATE(created_at)").limit(7).pluck("DATE(created_at)").last
      @activities = Activity.where(user: current_user).where("created_at > ?", start_date).order("created_at desc").group_by { |a| a.created_at.to_date }      
    else
      start_date = Activity.order("created_at desc").group("DATE(created_at)").limit(7).pluck("DATE(created_at)").last
      @activities = Activity.where("created_at > ?", start_date).order("created_at desc").group_by { |a| a.created_at.to_date }
    end

    @notifications = current_user.notifications
  end

end
