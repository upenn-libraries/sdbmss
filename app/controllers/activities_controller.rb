class ActivitiesController < ApplicationController

  before_action :authenticate_user!

  load_and_authorize_resource :only => [:index]

  # params[:day]
  def show_all
    if params[:mine]
      # finds last 7 days of activity - maybe too much?
      dates = Activity.where(user: current_user).order("created_at desc").group("DATE(created_at)").limit(7).pluck("DATE(created_at)")
      day = params[:day].to_i || 0
      @activities = Activity.where(user: current_user).where("created_at > ? and created_at <= ?", dates[day], (day - 1 >= 0 ? dates[day - 1] : Time.now)).order("created_at desc")     
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

      dates = Activity.where(query_string).order("created_at desc").group("DATE(created_at)").limit(7).pluck("DATE(created_at)")      
      day = params[:day].to_i || 0
      @activities = Activity.where(query_string).where("created_at > ? and created_at <= ?", dates[day], (day - 1 >= 0 ? dates[day - 1] : Time.now)).order("created_at desc")
    else
      dates = Activity.order("created_at desc").group("DATE(created_at)").limit(7).pluck("DATE(created_at)")
      day = params[:day].to_i || 0
      @activities = Activity.includes(:user).where("created_at > ? and created_at <= ?", dates[day], (day - 1 >= 0 ? dates[day - 1] : Time.now)).order("created_at desc")
      #@activities = Activity.includes(:user).where("created_at > ?", dates.last).order("created_at desc")     
    end
    @versions = PaperTrail::Version.where(transaction_id: @activities.map(&:transaction_id).flatten.uniq).includes(:item).order("created_at DESC")
    @users = User.where(id: @versions.map(&:whodunnit).uniq)
    @details = EntryVersionFormatter.new(@versions).details
    render partial: "activities/list"
    #render partial: "activities/show_all"
  end

  # fix me: replace 'show all' or 'list' with 'index.json.jbuilder'; it's only one method, no?

  def index
    @page_size = 25
    @page = (params["page"] || 1).to_i
    @activities = []
    last = 0
    #start_date = Activity.order("created_at desc").group("DATE(created_at)").limit(7).pluck("DATE(created_at)").last
    @activities = Activity.includes(:user).where(params_for_index).limit(@page_size).offset((@page - 1) * @page_size).order("created_at desc")
    @versions = PaperTrail::Version.where(transaction_id: @activities.map(&:transaction_id).flatten.uniq).includes(:item).order("created_at DESC")
    @users = User.where(id: @versions.map(&:whodunnit).uniq)
    @details = EntryVersionFormatter.new(@versions).details
    @total = Activity.includes(:user).where(params_for_index).count

    #@activities = Activity.joins(:user).where(params_for_index).order(id: :desc).limit(@page_size).offset((@page - 1) * @page_size)
    @num_pages = @total / @page_size
    @num_pages += 1 if @total % @page_size > 0

    @summary = {
      actions_performed: Hash[Activity.joins(:user).where(params_for_index).group(:event).count.sort_by { |_, v| -v }],
      records_affected: Hash[Activity.joins(:user).where(params_for_index).group(:item_type).select(:item_id).distinct.count.sort_by { |_, v| -v }],
      active_users: Hash[Activity.joins(:user).where(params_for_index).group(:username).count.sort_by { |_, v| -v }]
    }
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