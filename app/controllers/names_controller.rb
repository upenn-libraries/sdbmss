class NamesController < SearchableAuthorityController

  include ResourceSearch
  include MarkAsReviewed
  include ResetReviewedAfterUpdate
  include LogActivity

  include Revert

  load_and_authorize_resource :only => [:edit, :update, :destroy, :mark_as_reviewed, :merge]

  before_action :set_model, only: [:show, :show_json, :edit, :update, :destroy, :merge]

  def search_fields
    @fields = ["name"]
    @filters = ["id", "created_by", "updated_by", "viaf_id"]
    @fields + @filters
  end

  def model_class
    Name
  end

  def search_result_format(obj)
    {
      id: obj.id,
      name: obj.name,
      viaf_id: obj.viaf_id,
      authors_count: obj.authors_count || 0,
      artists_count: obj.artists_count || 0,
      scribes_count: obj.scribes_count || 0,
      source_agents_count: obj.source_agents_count || 0,
      sale_agents_count: obj.sale_agents_count || 0,
      provenance_count: obj.provenance_count || 0,
      is_artist: obj.is_artist,
      is_author: obj.is_author,
      is_provenance_agent: obj.is_provenance_agent,
      is_scribe: obj.is_scribe,
      reviewed: obj.reviewed,
      created_by: obj.created_by.present? ? obj.created_by.username : "(none)",
      created_at: obj.created_at.present? ? obj.created_at.to_formatted_s(:long) : "",
      updated_by: obj.updated_by.present? ? obj.updated_by.username : "(none)",
      updated_at: obj.updated_at.present? ? obj.updated_at.to_formatted_s(:long) : ""
    }
  end

  def search_query_base
    search_model_class.all.includes([:created_by])
  end

  def search_query
    query = super
    if params[:type].present?
      query = query.where(params[:type].to_sym => true)
    end
    query
  end

  def suggest
    name = params[:name]

    suggestions = Name.suggestions(name)

    respond_to do |format|
      format.json { render :json => suggestions, :status => :ok }
    end
  end

  def merge
    @target_id = params[:target_id]
    @target = nil
    params[:name] = @model.name
    get_similar
    if @target_id.present?
      if @target_id.to_i == @model.id
        @warning = "You can't merge a record into itself"
      else
        @target = Name.find_by(id: @target_id)
      end
    end
    if params[:confirm] == "yes"
      @model.merge_into(@target)
      render "merge_success"
    end
  end

  private

  def get_similar_old
    filtered = params.permit(:name, :is_author, :is_scribe, :is_artist, :is_provenance_agent)
    name = filtered['name']

    query = Name.none

    if name.present?
      query = Name.all

      # remove leading and trailing quotation marks and apostrophes
      words = name.split.select { |word| word.length > 3 }.map { |word| word.gsub(/^['"]/, '').gsub(/['"]$/, '') }

      words = words.map { |word| word.gsub(/"/, '\"') }

      # find titles that have ANY words in new title
      query = query.where(words.map { |word| "name LIKE \"%#{word}%\"" }.join(" OR "))

      # whittle them down by string similarity
      len = name.length
      query = query.where("length(name) <= #{len+8} AND length(name) >= #{len-8} AND levenshtein_ratio(name, ?) <= 40", name)

      query = query.limit(5)
    end

    @similar = query
  end

  def model_params
    # wrapped parameters don't work when class name is the same as one
    # of the fields. BUT Rails' HTML form helpers send URL parameters
    # in a format that Rails WILL translate into a wrapped format. So
    # we have to account for both cases, which is this grossness here.

    # if 'name' contains something other than a string, treat it as wrapped parameters
    if params[:name].present? && !params[:name].is_a?(String)
      p = params.require(:name)
    else
      p = params
    end
    p.permit(:name, :comment, :viaf_id, :is_artist, :is_author, :is_provenance_agent, :is_scribe)
  end

  def deletable?(object)
    deletable = true
    if (object.authors_count || 0) > 0 ||
       (object.artists_count || 0) > 0 ||
       (object.scribes_count || 0) > 0 ||
       (object.source_agents_count || 0) > 0 ||
       (object.sale_agents_count || 0) > 0 ||
       (object.provenance_count || 0) > 0
      deletable = false
    end
    deletable
  end

  def params_for_search
    params.permit(:name, {:name => []})
  end

  def filters_for_search
    params.permit(:id, :created_by, :updated_by, {:id => []}, {:created_by => []}, {:updated_by => []}, :viaf_id, {:viaf_id => []})
  end

end
