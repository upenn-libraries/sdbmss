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
    @source = Source.new
    @source.created_by_id = current_user.id
    update
  end

  def edit
  end

  def update
    begin
      ActiveRecord::Base.transaction do
        @source.update!(
          source_params.permit(
          :source_type, :date, :title, :author,
          :whether_mss,
          :medium, :date_accessed,
          :location_institution, :location,
          :link,
          :comments,
        ))

        if !@source.persisted?
          if @source.whether_mss == Source::TYPE_HAS_MANUSCRIPT_NO
            @source.status = Source::TYPE_STATUS_NO_MSS
          else
            @source.status = Source::TYPE_STATUS_TO_BE_ENTERED
          end
        end

        Reconciler.reconcile_assoc @source, source_params["source_agents"], SourceAgent, 'source_id', [:role, :agent_id]

      end
    rescue Exception => e
      render :json => { :errors => e.to_s + "\n" + e.backtrace.to_s }, :status => :unprocessable_entity
      return
    end
    respond_with(@source)
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
    ["id desc", "title"]
  end

  def search_result_format(obj)
    {
      id: obj.id,
      date: obj.date,
      source_type: obj.source_type,
      entries_count: obj.entries_count,
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
          render status: :unprocessable_entity, html: "Invalid status" if error.present?
        end
      }
      format.json {
        if error.blank?
          render nothing: true
        else
          render status: :unprocessable_entity, json: { "error" => "Invalid status" } if error.present?
        end
      }
    end
  end

  # returns JSON containing type constants
  def types
    data = {
      'source_type' => Source::SOURCE_TYPES,
      'medium' => Source::MEDIUM_TYPES,
    }
    render json: data
  end

  # we don't ever destroy anything, we just mark it as deleted
  def destroy
    @source.deleted = true
    @source.updated_by_id = current_user.id
    @source.save!

    # if we call respond_with(@entry), which is more rails-ish, the
    # response is a 302 to a #show, but jquery's ajax code gets stuck
    # in an redirect loop, deleting the object over and over again. So
    # we force-return a 200 with an empty body for JSON calls to this
    # action.
    respond_to do |format|
      format.json { render :json => {}, :status => :ok }
    end
  end

  private

  def set_source
    @source = Source.find(params[:id])
  end

  def source_params
    params.require(:source)
  end

end
