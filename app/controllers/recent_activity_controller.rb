
class RecentActivityController < ApplicationController

  before_action :authenticate_user!

  helper_method :link_for_model_object

  def show
    @activities = Activity.order(id: :desc).limit(50)
  end

end
