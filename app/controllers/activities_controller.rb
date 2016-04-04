
class ActivitiesController < ApplicationController

  before_action :authenticate_user!

  def index
    @page_size = 25
    @page = (params["page"] || 1).to_i
    @activities = []
    last = 0
    @activities = Activity.joins(:user).where(params_for_index).order(id: :desc).limit(@page_size).offset((@page - 1) * @page_size)
    @total = Activity.joins(:user).where(params_for_index).count

    @num_pages = @total / @page_size
    @num_pages += 1 if @total % @page_size > 0

    @summary = {
      actions_performed: Hash[Activity.joins(:user).where(params_for_index).group(:event).count.sort_by { |_, v| -v }],
      records_affected: Hash[Activity.joins(:user).where(params_for_index).group(:item_type).select(:item_id).distinct.count.sort_by { |_, v| -v }],
      active_users: Hash[Activity.joins(:user).where(params_for_index).group(:username).count.sort_by { |_, v| -v }]
    }

    @summary[:actions_performed][:total] = @total
    @summary[:records_affected][:total] = Activity.joins(:user).where(params_for_index).select(:item_id).distinct.count
    @summary[:active_users][:total] = @summary[:active_users].count

    if params[:more]
      render partial: "activities/more"
    end
  end

  def params_for_index
    hash = {}
    hash[:users] = params[:users] if (!params[:users].blank? && !params[:users][:username][0].blank?)
    hash[:event] = params[:event] if !params[:event].blank?
    hash[:item_type] = params[:item_type] if !params[:item_type].blank?
    start_date = params[:start_date] && params[:start_date][0].present? ? Date.parse(params[:start_date][0]) : Date.new(1900)
    end_date = params[:end_date] && params[:end_date][0].present? ? Date.parse(params[:end_date][0]) : Date.today + 1.day
    hash[:created_at] = start_date..end_date
    hash
  end

end
