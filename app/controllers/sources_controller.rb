class SourcesController < ApplicationController
  include ResourceSearch

  def show
    @source = Source.find(params[:id])
  end

  def find_by_search_terms class_name
    date = params.fetch(:date, '').gsub('-', '').gsub('/', '')
    title = params[:title]
    agent = params[:agent]
    query = class_name.all
    query = query.where('date like ?', "#{date}%") if date.present?
    query = query.where('title like ?', "%#{title}%") if title.present?
    query = query.joins(source_agents: [ :agent ] ).where('agents.name like ?', "%#{agent}%") if agent.present?
    query
  end

  def display_value_for_search obj
    "#{obj.get_display_value}"
  end

end
