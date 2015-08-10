
class EntryManuscriptsController < ApplicationController

  before_action :authenticate_user!, only: [:update_multiple]

#  respond_to :html, :json

  def create
    @entry_manuscript = EntryManuscript.new(entry_manuscript_params)
    @entry_manuscript.save!
    respond_to do |format|
      format.json {
        render json: @entry_manuscript
      }
    end
  end

  # updates multiple EntryManuscript records at once; this is used for
  # the Linking Tool
  def update_multiple
    manuscript = Manuscript.find params[:manuscript_id]

    if params[:cumulative_updated_at].to_s == manuscript.cumulative_updated_at.to_s
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
    else
      respond_to do |format|
        format.json {
          render :json => { :errors => { :base => "Another change was made to the record while you were working. Re-load the page and start over." } }, :status => :unprocessable_entity
        }
      end
    end
  end

  private

  def entry_manuscript_params
    params.require(:entry_manuscript).permit(:entry_id, :manuscript_id, :relation_type)
  end

end
