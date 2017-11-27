class DericciNotesController < ApplicationController

  def index
    flash.now[:alert] = "<span class='lead'>Warning!</span> The server hosting the De Ricci Digitized Archive is not available.  Our records and workspace will not function correctly.".html_safe
    @page = params[:page] ? params[:page].to_i : 0
    @notes = DericciNote.limit(20).offset(@page * 20)
  end

end