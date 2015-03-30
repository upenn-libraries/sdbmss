class SourcesController < ApplicationController
  include ResourceSearch

  wrap_parameters include: Source.attribute_names - ['created_at', 'created_by', 'updated_at', 'updated_by'] + ['source_agents']

  before_action :set_source, only: [:show, :edit, :update, :destroy, :update_status]

  before_action :authenticate_user!, only: [:index, :new, :create, :edit, :update, :destroy, :search]

  respond_to :html, :json

  def new
    @source = Source.new
    respond_to do |format|
      format.html { render "edit" }
    end
  end

  def create
    filtered = source_params_for_create_and_edit
    @source = Source.new(filtered)
    if @source.whether_mss == Source::TYPE_HAS_MANUSCRIPT_NO
      @source.status = Source::TYPE_STATUS_NO_MSS
    else
      @source.status = Source::TYPE_STATUS_TO_BE_ENTERED
    end
    @source.created_by_id = current_user.id
    @source.save!
    render "show"
  end

  def edit
  end

  def update
    begin
      ActiveRecord::Base.transaction do
        filtered = source_params_for_create_and_edit
        @source.update!(filtered)
      end
    rescue Exception => e
      render :json => { :errors => e.to_s + "\n" + e.backtrace.to_s }, :status => :unprocessable_entity
      return
    end
    render "show"
  end

  def search_exact_enabled
    false
  end

  def search_query
    date = params.fetch(:date, '').gsub('-', '').gsub('/', '')
    title = params[:title]
    agent = params[:agent]
    query = Source.all
    query = query.where('date like ?', "#{date}%") if date.present?
    query = query.where('title like ?', "%#{title}%") if title.present?
    query = query.joins(source_agents: [ :agent ] ).where('agents.name like ?', "%#{agent}%") if agent.present?
    query.load_associations
  end

  def search_results_order
    [params["order"] || ["date desc", "title"]]
  end

  def search_result_format(obj)
    {
      id: obj.id,
      date: obj.date,
      source_type: obj.source_type.display_name,
      entries_count: obj.entries_count || 0,
      title: obj.title,
      display_value: obj.display_value,
      author: obj.author,
      selling_agent: (selling_agent = obj.get_selling_agent_as_name).present? ? selling_agent.name : "",
      institution: (institution_agent = obj.get_institution_as_name).present? ? institution_agent.name : "",
      whether_mss: obj.whether_mss,
      medium: obj.medium_for_display,
      date_accessed: obj.date_accessed,
      location_institution: obj.location_institution,
      location: obj.location,
      link: obj.link,
      comments: obj.comments,
    }
  end

  # change the status of a Source
  def update_status
    new_status = params[:status]
    error = nil
    if Source::STATUS_TYPES.map(&:first).member? new_status
      @source.status = new_status
      @source.save!
    else
      error = "Invalid status"
    end

    respond_to do |format|
      format.html {
        if error.blank?
          render nothing: true
        else
          render status: :unprocessable_entity, html: "Invalid status"
        end
      }
      format.json {
        if error.blank?
          render nothing: true
        else
          render status: :unprocessable_entity, json: { "error" => "Invalid status" }
        end
      }
    end
  end

  # returns JSON containing type constants
  def types
    data = {
      'source_type' => SourceType.all,
      'medium' => Source::MEDIUM_TYPES,
    }
    render json: data
  end

  # we don't ever destroy anything, we just mark it as deleted
  def destroy
    error = nil
    if @source.entries_count.to_i == 0
      @source.deleted = true
      @source.updated_by_id = current_user.id
      @source.save!
    else
      error = "Can't mark a source as deleted if it has entries"
    end

    # if we call respond_with(@entry), which is more rails-ish, the
    # response is a 302 to a #show, but jquery's ajax code gets stuck
    # in an redirect loop, deleting the object over and over again. So
    # we force-return a 200 with an empty body for JSON calls to this
    # action.
    respond_to do |format|
      format.json {
        if !error
          render :json => {}, :status => :ok
        else
          render status: :unprocessable_entity, json: { "error" => error }
        end
      }
    end
  end

  private

  def set_source
    @source = Source.find(params[:id])
  end

  def source_params
    params.require(:source)
  end

  def source_params_for_create_and_edit
    # Note that we don't call require(:source), which is the typical
    # Rails convention, because Rails' wrapped parameters feature
    # doesn't pick up the *_attributes fields that way.
    params.permit(
      :source_type_id,
      :date,
      :title,
      :author,
      :whether_mss,
      :medium,
      :date_accessed,
      :location,
      :location_institution,
      :link,
      :comments,
      :source_agents_attributes => [ :id, :agent_id, :role, :_destroy ],
    )
  end

end
