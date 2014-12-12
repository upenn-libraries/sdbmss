class AgentsController < ApplicationController

  def show
    @agent = Agent.find(params[:id])
  end

end
