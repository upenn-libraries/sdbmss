class LanguagesController < SearchableAuthorityController

  include LanguagesAndPlaces
  include MarkAsReviewed
  include LogActivity

  include Revert

  load_and_authorize_resource :only => [:index, :edit, :update, :destroy, :mark_as_reviewed]

  def model_class
    Language
  end

  def merge
    @model = Language.find(params[:id])

    # select
    if !params[:target_id]
      @suggestions = @model.more_like_this.results
    # confirm
    else      
      @target = Language.find(params[:target_id])
    end

    if params[:confirm]
      # merge!
      ActiveRecord::Base.transaction do
        id = @model.public_id
        @model.entry_languages.update_all(:language_id => @target.id)
        @model.destroy!
        flash[:success] = "#{id} has been successfully merged into #{@target.public_id}"
        @target.entries.index
        Language.update_counters(@target.id, :entries_count => @target.entries.count - @target.entries_count)
        redirect_to language_path(@target)
      end
    else
      # nothing, handle normally
    end
  end

end
