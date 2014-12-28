class AgentsController < ApplicationController
  before_action :set_agent, only: [:show, :show_json, :edit, :update, :destroy]

  include ResourceSearch

  def create
    @agent = Agent.new(params.permit(:name))
    @agent.save!
  end

  private

  def set_agent
    @agent = Agent.find(params[:id])
  end

end
