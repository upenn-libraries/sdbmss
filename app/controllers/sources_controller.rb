class SourcesController < ApplicationController
  include ResourceSearch

  before_action :set_source, only: [:show, :edit, :update, :destroy]

  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy]

  respond_to :html, :json

  def new
  end

  def create
    @source = Source.new
    @source.created_by_id = current_user.id
    update
  end

  def update
    begin
      ActiveRecord::Base.transaction do
        @source.update!(
          params.permit(
          :source_type, :date, :title, :author,
          :whether_mss, :status,
          :alt_date, :current_location, :location_city, :location_country,
          :link,
          :cataloging_type,
          :electronic_catalog_format,
          :electronic_catalog_open_access,
          :sources,
        ))

        Reconciler.reconcile_assoc @source, params["source_agents"], SourceAgent, 'source_id', [:role, :agent_id]

      end
    rescue Exception => e
      render :json => { :errors => e.to_s + "\n" + e.backtrace.to_s }, :status => 500
      return
    end
    respond_with(@source)
  end

  def show
    @source = Source.find(params[:id])
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

  private

  def set_source
    @source = Source.find(params[:id])
  end

end
