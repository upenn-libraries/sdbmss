
# The "Linking Tool" is the name of the two highly similar screens
# through which Entries get associated Manuscripts.
class LinkingToolController < ApplicationController

  def by_entry
    authorize! :link, Entry
    @mode = "by_entry"
    @entry = Entry.find(params[:id])
    if @entry.manuscript.blank?
      render "show"
    else
      redirect_to :action => "by_manuscript", :id => @entry.manuscript.id
    end
  end

  def by_manuscript
    authorize! :link, Manuscript
    @mode = "by_manuscript"
    @manuscript = Manuscript.find(params[:id])
    render "show"
  end

end
