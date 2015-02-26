class AgentsController < ApplicationController
  include ResourceSearch

  before_action :set_agent, only: [:show, :show_json, :edit, :update, :destroy]

  def create
    @agent = Agent.new(agent_params)
    @agent.save!
  end

  private

  def set_agent
    @agent = Agent.find(params[:id])
  end

  def agent_params
    params.require(:agent).permit(:name)
  end

end
