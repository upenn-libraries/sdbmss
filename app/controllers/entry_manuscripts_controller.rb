
class EntryManuscriptsController < ManageModelsController

  before_action :authenticate_user!, only: [:update_multiple]

  include ResourceSearch
  include MarkAsReviewed
  include LogActivity

  #  respond_to :html, :json

  def index
    @page_title = "Manage Links"
  end

  # updates multiple EntryManuscript records at once; this is used for
  # the Linking Tool
  def update_multiple
    manuscript = Manuscript.find params[:manuscript_id]

    @entry_manuscripts = []

    if params[:cumulative_updated_at].to_s == manuscript.cumulative_updated_at.to_s
      params[:entry_manuscripts].each do |record|
        attrs = record.permit(:id, :entry_id, :manuscript_id, :relation_type, :_destroy)
        if record["_destroy"]
          em = EntryManuscript.find(record["id"])
          em.destroy!
        elsif record["id"]
          em = EntryManuscript.find(record["id"])
          em.update_attributes!(attrs)
        else
          em = EntryManuscript.new(attrs)
          em.manuscript_id = manuscript.id
          em.save!
        end
        @entry_manuscripts << em
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

  def search_name_field
    # This is weird, but we don't have a name field in this model
    "id"
  end

  def search_result_format(obj)
    {
      id: obj.id,
      entry_id: obj.entry_id,
      manuscript_id: obj.manuscript_id,
      relation_type: obj.relation_type,
      reviewed: obj.reviewed,
      created_by: obj.created_by.present? ? obj.created_by.username : "(none)",
      created_at: obj.created_at.present? ? obj.created_at.to_formatted_s(:short) : "",
      updated_by: obj.updated_by.present? ? obj.updated_by.username : "(none)",
      updated_at: obj.updated_at.present? ? obj.updated_at.to_formatted_s(:short) : ""
    }
  end

  private

  def model_params
    params.require(:entry_manuscript).permit(:entry_id, :manuscript_id, :relation_type)
  end

end
