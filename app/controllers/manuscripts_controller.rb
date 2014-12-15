class ManuscriptsController < ApplicationController

  def show
    @manuscript = Manuscript.find(params[:id])
  end

end
