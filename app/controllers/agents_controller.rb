
# Provenance agents are stored in the database as Names but we expose
# a read-only view because we want to highlight and differentiate
# provenance agents as important to the domain of the SDBM project.
class AgentsController < ApplicationController

  before_action :set_agent, only: [:show, :show_json, :edit, :update, :destroy]

  private

  def set_agent
    @agent = Name.where(id: params[:id], is_provenance_agent: true).first
  end

  def agent_params
    params.require(:agent).permit(:name)
  end

end
