class DericciNotesController < ApplicationController

  def index
    @page = params[:page] ? params[:page].to_i : 0
    @notes = DericciNote.limit(20).offset(@page * 20)
  end

end