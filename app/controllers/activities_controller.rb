
class ActivitiesController < ApplicationController

  before_action :authenticate_user!

  def index
    page_size = 25
    total = Activity.count
    @num_pages = total / page_size
    @num_pages += 1 if total % page_size > 0
    @page = (params["page"] || 1).to_i
    @activities = Activity.order(id: :desc).limit(page_size).offset((@page - 1) * page_size)
  end

end
