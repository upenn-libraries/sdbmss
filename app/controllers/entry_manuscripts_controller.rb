
class EntryManuscriptsController < SearchableAuthorityController

  include MarkAsReviewed
  include LogActivity

  def index
    super
    @page_title = "Manage Links"
  end

  def show
    redirect_to manuscript_path(EntryManuscript.find(params[:id]).manuscript)
  end

  # updates multiple EntryManuscript records at once; this is used for
  # the Linking Tool
  def update_multiple
    ActiveRecord::Base.transaction do
      
      manuscript = Manuscript.find params[:manuscript_id]

      @entry_manuscripts = []

      if params[:cumulative_updated_at].to_s == manuscript.cumulative_updated_at.to_s
        params[:entry_manuscripts].each do |record|
          attrs = record.permit(:id, :entry_id, :manuscript_id, :relation_type, :_destroy)
          if !Entry.exists? record["entry_id"]
            # pass 
          elsif record["_destroy"]
            em = EntryManuscript.find(record["id"])
            em.destroy!
          elsif record["id"]
            em = EntryManuscript.find(record["id"])
            em.updated_by = current_user;
            em.update_attributes!(attrs)
          else
            em = EntryManuscript.new(attrs)
            em.manuscript_id = manuscript.id
            em.created_by = current_user;
            em.updated_by = current_user;
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

      @transaction_id = PaperTrail.transaction_id
      manuscript.touch_with_version
      manuscript.try(:create_activity, "update", current_user, @transaction_id)
    end
  end

  private

  def model_params
    params.require(:entry_manuscript).permit(:entry_id, :manuscript_id, :relation_type)
  end

end
