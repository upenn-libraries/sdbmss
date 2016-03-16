
class ActivitiesController < ApplicationController

  before_action :authenticate_user!

  def index
    page_size = 25
    @page = (params["page"] || 1).to_i
    @activities = []
    last = 0
    activity_list = Activity.joins(:user).where(params_for_index).order(id: :desc).limit(page_size).offset((@page - 1) * page_size)
    @total = Activity.joins(:user).where(params_for_index).count

    @num_pages = @total / page_size
    @num_pages += 1 if @total % page_size > 0
    activity_list.each do |activity|
      if !@activities[last]
        @activities[last] = [activity]
      elsif @activities[last].first.user_id == activity.user_id && @activities[last].first.item_type == activity.item_type && @activities[last].first.event == activity.event
        @activities[last].append(activity)
      else
        last += 1
        @activities.append([activity])
      end
    end
    respond_to do |format|
      format.html {
      }
      format.json {
        render json: @activities
      }
    end
  end

  def params_for_index
    hash = {}
    hash[:users] = params[:users] if (!params[:users].blank? && !params[:users][:username][0].blank?)
    hash[:event] = params[:event] if !params[:event].blank?
    hash[:item_type] = params[:item_type] if !params[:item_type].blank?
    hash
    # the (below) does not work, for some reason, so I did it manually (above)... thanks rails!
    #params.permit(:event, :item_type, :users => [:username]).reject{|_, v| v.blank?}
  end

end
