# handle links from the old dla website

class LegacyController < ApplicationController
  def index
    entry_id = params[:id].to_s.gsub('SCHOENBERG_', '')
    if Entry.exists?(id: entry_id)
      redirect_to entry_path(Entry.find(entry_id))
    else
      flash[:notice] = "Record not found."
      redirect_to root_path
    end
  end
end