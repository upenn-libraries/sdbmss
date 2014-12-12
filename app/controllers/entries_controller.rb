class EntriesController < ApplicationController

  def show
    @source = Source.find(params[:id])
  end

end
