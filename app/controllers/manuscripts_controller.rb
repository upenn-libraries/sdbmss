class ManuscriptsController < ApplicationController

  before_action :set_manuscript, only: [:show, :edit]

  private

  def set_manuscript
    @manuscript = Manuscript.find(params[:id])
  end

end
