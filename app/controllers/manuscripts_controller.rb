class ManuscriptsController < SearchableAuthorityController

  include MarkAsReviewed
  include LogActivity

  before_action :set_manuscript, only: [:show, :edit, :entry_candidates, :citation]

  load_and_authorize_resource :only => [:edit, :update, :destroy, :mark_as_reviewed]

  def model_class
    Manuscript
  end

  def search_fields
    @fields = ["name", "location", "created_by", "updated_by"]
    @filters = ["id"]
    @dates = ["created_at", "updated_at"]
    @fields + @filters + @dates
  end

  def show
    @manuscript_comment = ManuscriptComment.new(manuscript: @manuscript)
    @manuscript_comment.build_comment

    @manuscript_titles = @manuscript.all_titles
    @entries = @manuscript.entries.joins(:source).order("date desc")
    @entries.reject { |e| e.source.date.blank? }.each do |e|
      if e.institution
        @location_source = e.source
        @location_name = e.institution
        @location = e
        return
      elsif e.sale && e.sale.sale_agents.count > 0
        @location_source = e.source
        @location = e
        if e.sale_agent('buyer')
          @location_name = e.sale_agent('buyer')
        elsif e.sale_agent('seller_or_holder')
          @location_name = e.sale_agent('seller_or_holder')
        else 
          @location_name = e.sale_agent('selling_agent')
        end
        return
      elsif e.source.source_agents.count > 0
        @location_source = e.source
        @location = e
        @location_name = e.source.source_agents.first.agent
        return
      end
    end
  end

  def update
    super
  end

  def entry_candidates
    @candidate_ids = @manuscript.entry_candidates
    respond_to do |format|
      format.json
    end
  end

  def search_result_format(obj)
    {
      id: obj.id,
      name: obj.name,
      location: obj.location,
      entries_count: obj.entries_count,
      reviewed: obj.reviewed,
      created_by: obj.created_by.present? ? obj.created_by.username : "(none)",
      created_at: obj.created_at.present? ? obj.created_at.to_formatted_s(:long) : "",
      updated_by: obj.updated_by.present? ? obj.updated_by.username : "(none)",
      updated_at: obj.updated_at.present? ? obj.updated_at.to_formatted_s(:long) : ""
    }
  end

  def citation
    respond_to do |format|
      format.js
    end
  end

  def destroy
    if deletable?(@model)
      if @model.destroy
        respond_to do |format|
          format.json {
            render status: :ok, json: {}
          }
          format.html {
            redirect_to names_path
          }
        end
      else
        respond_to do |format|
          format.json {
            render status: :unprocessable_entity, json: { "error" => @model.errors.join("; ") }
          }
          format.html {
            flash[:error] = @model.errors.join("; ")
            redirect_to :action => "edit", :id => @model.id
          }
        end
      end
    else
      respond_to do |format|
        format.json {
          render status: :unprocessable_entity, json: { "error" => "Record is not deletable, probably because other records are associated with it" }
        }
        format.html {
          flash[:error] = "Record is not deletable, probably because other records are associated with it."
          redirect_to :action => "edit", :id => @model.id
        }
      end
    end
  end

  private

  def set_manuscript
    @manuscript = Manuscript.find(params[:id])
  end

  def model_params
    params.require(model_class_lstr.to_sym).permit(
      :name, :location, :url,
      :entry_manuscripts_attributes => [ :id, :manuscript_id, :entry_id, :relation_type, :_destroy ]
    )
  end

  #def params_for_search
  #  params.permit(:name, {:name => []}, :location, {:location => []}, :created_by, :updated_by, {:created_by => []}, {:updated_by => []})
  #end

end
