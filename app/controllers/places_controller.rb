class PlacesController < SearchableAuthorityController

  include LanguagesAndPlaces
  include MarkAsReviewed
  include LogActivity

  include Revert

  load_and_authorize_resource :only => [:index, :edit, :update, :destroy, :mark_as_reviewed, :merge]

  def model_class
    Place
  end

  def show
    super
    # pagination variables for associated names
    #@page = params[:page].to_i || 0
    #@total = @model.name_places.joins(:name).where("names.name like ?", "#{params[:letter]}%").offset(@page * 10).order("names.name").count
    #@lower = @page * 10
    #@upper = [@total, (@page + 1) * 10].min
    #@pages = (@total / 10).ceil
    #@name_places = @model.name_places.joins(:name).where("names.name like ?", "#{params[:letter]}%").offset(@page * 10).order("names.name").limit(10)
    @page_size = 10
    @name_places = @model.name_places.joins(:name).order("names.name")
    respond_to do |format|
      format.html { }
      format.json { render json: @model.search_result_format }
    end
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
        @model.children.update_all(:parent_id => @target.id)
        @model.destroy!
        flash[:success] = "#{id} has been successfully merged into #{@target.public_id}"
        entry_ids = @target.entries.map(&:id)
        entry_ids.each_slice(200) do |slice|
          SDBMSS::IndexJob.perform_later(Entry.to_s, slice)
        end
        Place.update_counters(@target.id, :entries_count => @target.entries.where(deprecated: false, draft: false).count - @target.entries_count)
        redirect_to place_path(@target)
      end
    else
      # nothing, handle normally
    end
  end

  def model_params
    params.require(:place).permit(:name, :reviewed, :problem, :latitude, :longitude, :authority_source, :authority_id, :parent_id, :evidence)
  end

end
