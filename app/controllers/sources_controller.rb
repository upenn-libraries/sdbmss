class SourcesController < ApplicationController
  include ResourceSearch

  before_action :set_source, only: [:show, :edit, :update, :destroy, :update_status]

  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy]

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
          params.permit(
          :source_type, :date, :title, :author,
          :whether_mss,
          :current_location, :location_city, :location_country,
          :link,
          :cataloging_type,
          :electronic_catalog_format,
          :electronic_publicly_available,
          :comments,
        ))

        if !@source.persisted?
          if @source.whether_mss == Source::TYPE_HAS_MANUSCRIPT_NO
            @source.status = Source::TYPE_STATUS_NO_MSS
          else
            @source.status = Source::TYPE_STATUS_TO_BE_ENTERED
          end
        end

        Reconciler.reconcile_assoc @source, params["source_agents"], SourceAgent, 'source_id', [:role, :agent_id]

      end
    rescue Exception => e
      render :json => { :errors => e.to_s + "\n" + e.backtrace.to_s }, :status => 500
      return
    end
    respond_with(@source)
  end

  def find_by_search_terms class_name
    date = params.fetch(:date, '').gsub('-', '').gsub('/', '')
    title = params[:title]
    agent = params[:agent]
    query = class_name.all.order('date desc', 'title')
    query = query.where('date like ?', "#{date}%") if date.present?
    query = query.where('title like ?', "%#{title}%") if title.present?
    query = query.joins(source_agents: [ :agent ] ).where('agents.name like ?', "%#{agent}%") if agent.present?
    query
  end

  def display_value_for_search obj
    "#{obj.get_display_value}"
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
          render status: 500, html: "Invalid status" if error.present?
        end
      }
      format.json {
        if error.blank?
          render nothing: true
        else
          render status: 500, json: { "error" => "Invalid status" } if error.present?
        end
      }
    end
  end

  private

  def set_source
    @source = Source.find(params[:id])
  end

end
