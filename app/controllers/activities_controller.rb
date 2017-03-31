
class ActivitiesController < ApplicationController

  before_action :authenticate_user!

  load_and_authorize_resource :only => [:index]

  def show_all
    if params[:mine]
      # finds last 7 days of activity - maybe too much?
      start_date = Activity.where(user: current_user).order("created_at desc").group("DATE(created_at)").limit(7).pluck("DATE(created_at)").last
      @activities = Activity.where(user: current_user).where("created_at > ?", start_date).order("created_at desc").group_by { |a| a.created_at.to_date }      
    elsif params[:watched]
      #creates a long custom SQL query to collect the activity for all the records you are watching...
      
      manuscript_ids = current_user.watched_manuscripts.pluck(:id).join(',')
      entry_ids = current_user.watched_entries.pluck(:id).join(',')
      name_ids = current_user.watched_names.pluck(:id).join(',')
      source_ids = current_user.watched_sources.pluck(:id).join(',')

      manuscript_ids = '-1' if manuscript_ids.blank?
      entry_ids = '-1' if entry_ids.blank?
      name_ids = '-1' if name_ids.blank?
      source_ids = '-1' if source_ids.blank?

      queries = [
        "item_type = 'Manuscript' and item_id in (#{manuscript_ids})",
        "item_type = 'Entry' and item_id in (#{entry_ids})",
        "item_type = 'Name' and item_id in (#{name_ids})",
        "item_type = 'Source' and item_id in (#{source_ids})"
      ]
      query_string = queries.join(" or ")

      start_date = Activity.where(query_string).order("created_at desc").group("DATE(created_at)").limit(7).pluck("DATE(created_at)").last
      @activities = Activity.where(query_string).where("created_at > ?", start_date).order("created_at desc").group_by { |a| a.created_at.to_date }
    else
      start_date = Activity.order("created_at desc").group("DATE(created_at)").limit(7).pluck("DATE(created_at)").last
      @activities = Activity.where("created_at > ?", start_date).order("created_at desc").group_by { |a| a.created_at.to_date }
    end
    @versions = PaperTrail::Version.where(transaction_id: @activities.map{ |date, activities| activities.map(&:transaction_id) }.flatten.uniq).includes(:item)
    render partial: "activities/show_all"
  end

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