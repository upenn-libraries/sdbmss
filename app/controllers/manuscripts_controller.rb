class ManuscriptsController < SearchableAuthorityController

  include MarkAsReviewed
  include LogActivity

  before_action :set_manuscript, only: [:show, :edit, :entry_candidates, :citation, :table, :history]

  load_and_authorize_resource :only => [:edit, :update, :destroy, :mark_as_reviewed]

  rescue_from ActionController::UnknownFormat, with: :render_404
  rescue_from ActionController::InvalidCrossOriginRequest, with: :render_404

  def model_class
    Manuscript
  end

  def table
    @model = @manuscript
    @entries = @manuscript.entries.preload(
      :created_by, :updated_by, :contributors, :groups, :institution, 
      {:sales => [{:sale_agents => :agent}]}, 
      {:entry_authors => [:author]}, 
      :entry_titles, 
      :entry_dates, 
      {:entry_artists => [:artist]}, 
      {:entry_scribes => [:scribe]}, 
      {:entry_languages => [:language]}, 
      {:entry_places => [:place]}, 
      {:provenance => [:provenance_agent]},
      :entry_uses, :entry_materials, 
      {:entry_manuscripts => [:manuscript]}, 
      {:source => [{:source_agents => :agent}, :source_type]}, :bookmarks, :watches,
    ).sort do |a, b|
      a_date = a.source.date.present? ? a.source.date.to_i : a.source.date_accessed.to_i
      b_date = b.source.date.present? ? b.source.date.to_i : b.source.date_accessed.to_i
      b_date <=> a_date
    end
    # I use 'sort' rather than the query-based order because of a rails issue:
    # https://github.com/rails/rails/issues/6769
    # that breaks associated field ordering (i.e. provenance)
  end

  def show
    #flash.now[:notice] = "Note: This manuscript record aggregates entries citing a manuscript that is mentioned in sources or observations.  Do not assume that the manuscript is held by the University of Pennsylvania Libraries."

    #@manuscript_comment = ManuscriptComment.new(manuscript: @manuscript)
    #manuscript_comment.build_comment

    @manuscript_titles = @manuscript.all_titles
    @entries = @manuscript.entries.sort do |a, b|
      a_date = a.source.date.present? ? a.source.date.to_i : a.source.date_accessed.to_i
      b_date = b.source.date.present? ? b.source.date.to_i : b.source.date_accessed.to_i
      b_date <=> a_date
    end
    @entries.each do |e|
      if e.institution
        @location_source = e.source
        @location_name = e.institution
        @location = e
        return
      elsif e.sale && e.sale.sale_agents.count > 0
        @location_source = e.source
        @location = e
        if e.sale_agent('buyer').count > 0
          @location_name = e.sale_agent('buyer').first
        elsif e.sale_agent('seller_or_holder').count > 0
          @location_name = e.sale_agent('seller_or_holder').first
        else 
          @location_name = e.sale_agent('selling_agent').first
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

# this is no longer available anywhere in the public interface - but should it be?
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

  def history
    @model = Manuscript.find(params[:id])
    @versions = PaperTrail::Version.where(item_type: "EntryManuscript", transaction_id: Activity.where(item: @model).map(&:transaction_id))
    @users = User.find(@versions.pluck(:whodunnit))
    @details = EntryVersionFormatter.new(@versions).details
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
