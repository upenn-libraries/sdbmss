
# The "Linking Tool" is the name of the two highly similar screens
# through which Entries get associated Manuscripts.
class LinkingToolController < ApplicationController

  def options
    @search_fields = Entry.search_fields
    @fields = Entry.fields
    @filters = Entry.filters
    @dates = Entry.dates
    @filter_options = ["with", "without", "blank", "not blank", "less than", "greater than"]
    @field_options = ["contains", "does not contain", "blank", "not blank"]
    @date_options = ["before", "after", "near", "exact"]
  end

  def by_entry
    authorize! :link, Entry
    @mode = "by_entry"
    @entry = Entry.find(params[:id].to_i)
    options
    if @entry.manuscript.blank?
      render "show"
    else
      redirect_to :action => "by_manuscript", :id => @entry.manuscript.id
    end
  end

  def by_manuscript
    authorize! :link, Manuscript
    @mode = "by_manuscript"
    @manuscript = Manuscript.find(params[:id].to_i)
    options
    render "show"
  end

end
