class PlacesController < SearchableAuthorityController

  include LanguagesAndPlaces
  include MarkAsReviewed
  include LogActivity

  include Revert

  load_and_authorize_resource :only => [:index, :edit, :update, :destroy, :mark_as_reviewed]

  def model_class
    Place
  end

  def merge
    @model = Place.find(params[:id])

    # select
    if !params[:target_id]
      @suggestions = @model.more_like_this.results
    # confirm
    else      
      @target = Place.find(params[:target_id])
    end

    if params[:confirm]
      # merge!
      ActiveRecord::Base.transaction do
        id = @model.public_id
        @model.entry_places.update_all(:place_id => @target.id)
        @model.destroy!
        flash[:success] = "#{id} has been successfully merged into #{@target.public_id}"
        entry_ids = @target.entries.map(&:id)
        entry_ids.each_slice(200) do |slice|
          SDBMSS::IndexJob.perform_later(Entry.to_s, slice)
        end
        Place.update_counters(@target.id, :entries_count => @target.entries.count - @target.entries_count)
        redirect_to place_path(@target)
      end
    else
      # nothing, handle normally
    end
  end

end
