class NamesController < SearchableAuthorityController

  include LogActivity
  include MarkAsReviewed
  include ResetReviewedAfterUpdate

  include Revert

  load_and_authorize_resource :only => [:index, :edit, :update, :destroy, :mark_as_reviewed, :merge]

  before_action :set_model, only: [:show, :show_json, :edit, :update, :destroy, :merge]

  def model_class
    Name
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
    check_exists = params[:check_exists].present? ? params[:check_exists] == 'true' : true

    suggestions = Name.suggestions(name, check_if_name_already_exists: check_exists)

    respond_to do |format|
      format.json { render :json => suggestions, :status => :ok }
    end
  end

  def merge
    @target_id = params[:target_id]
    @target = nil
#    params[:name] = @model.name
    get_similar
    if @target_id.present?
      if @target_id.to_i == @model.id
        @warning = "You can't merge a record into itself"
      else
        @target = Name.find_by(id: @target_id)
      end
    end
    if params[:confirm] == "yes"
      ActiveRecord::Base.transaction do
        @target.update_attributes(merge_params)
        @target.save!
        id = @model.public_id
        @model.merge_into(@target)
        @transaction_id = PaperTrail.transaction_id
        @model = @target
        log_activity
        flash[:success] = "#{id} has been successfully merged into #{@target.public_id}"
      end
      redirect_to name_path(@target)
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
    p.permit(:name, :other_info, :viaf_id, :is_artist, :is_author, :is_provenance_agent, :is_scribe, :confirmed)
  end

  def merge_params
    params.permit(:name, :other_info, :viaf_id, :is_artist, :is_author, :is_provenance_agent, :is_scribe)
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

#  def params_for_search

#    params.permit(:name, {:name => []}, :created_by, :updated_by, {:created_by => []}, {:updated_by => []})
#  end

#  def filters_for_search
#    params.permit(:id, :created_by, :updated_by, {:id => []}, {:created_by => []}, {:updated_by => []}, :viaf_id, {:viaf_id => []})
#  end

end
