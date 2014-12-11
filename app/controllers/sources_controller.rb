class SourcesController < ApplicationController

  def show
    @source = Source.find(params[:id])
  end

end
