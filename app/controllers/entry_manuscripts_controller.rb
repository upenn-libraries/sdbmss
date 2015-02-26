
class EntryManuscriptsController < ApplicationController

  before_action :authenticate_user!, only: [:update_multiple]

#  respond_to :html, :json

  # updates multiple EntryManuscript records at once; this is used for
  # the Entry <-> Manuscript management tool
  def update_multiple
    manuscript = Manuscript.find params[:manuscript_id]

    entry_manuscripts = params[:entry_manuscripts]
    entry_manuscripts_attributes = entry_manuscripts.map do |entry_manuscript_params|
      entry_manuscript_params.permit(:id, :entry_id, :manuscript_id, :relation_type, :_destroy)
    end

    manuscript.update_attributes!(
      {
        entry_manuscripts_attributes: entry_manuscripts_attributes,
      }
    )

    manuscript.reload

    # reindex in Solr
    manuscript.entries.each do |entry|
      Sunspot.index entry
    end
    respond_to do |format|
      format.json { render :json => {}, :status => :ok }
    end
  end

end
