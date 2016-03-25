
class SourcesController < SearchableAuthorityController

  include CalculateBounds
  include MarkAsReviewed
  include LogActivity

  wrap_parameters include: Source.attribute_names - ['created_at', 'created_by', 'updated_at', 'updated_by'] + ['source_agents']

  before_action :set_source, only: [:show, :edit, :update, :destroy, :update_status]

  before_action :authenticate_user!, only: [:index, :new, :create, :edit, :update, :destroy, :search]

  respond_to :html, :json

  load_and_authorize_resource :only => [:edit, :update, :destroy]

  DEFAULT_SEARCH_FIELD_HANDLER = Proc.new { |fieldname, params, query|
    query.where("#{fieldname} like ?", "%#{params[fieldname]}%")
  }

  SEARCH_FIELDS = [
    ["title", "Title", DEFAULT_SEARCH_FIELD_HANDLER ],
    ["date", "Date", Proc.new { |fieldname, params, query|
       query.where("#{fieldname} like ?", "%#{params[fieldname].gsub('-', '').gsub('/', '')}%")
     }
    ],
    ["selling_agent", "Selling Agent", Proc.new { |fieldname, params, query|
       query.joins(source_agents: [ :agent ] ).where("source_agents.role = \"#{SourceAgent::ROLE_SELLING_AGENT}\" AND names.name like ?", "%#{params[fieldname]}%")
     }
    ],
    ["institution", "Institution", Proc.new { |fieldname, params, query|
       query.joins(source_agents: [ :agent ] ).where("source_agents.role = \"#{SourceAgent::ROLE_INSTITUTION}\" AND names.name like ?", "%#{params[fieldname]}%")
     }
    ],
    ["author", "Author", DEFAULT_SEARCH_FIELD_HANDLER ],
  ]

  def search_fields
    @filters = ["id", "created_by", "updated_by", "location"]
    @fields = ["title", "selling_agent", "institution", "author"]
    @dates = ["created_at", "updated_at"]
    @fields + @filters + @dates
  end

  # return just the query strings which are combined in an array, then joined with either AND or OR to create one final query - but will it work with the unique cases above?

  A_DEFAULT_SEARCH_HANDLER = lambda { |fieldname, params, query| 
    return "#{fieldname} like '%#{params[fieldname]}%'"
  }

  A_SEARCH_FIELDS = [
    ["title", "Title", A_DEFAULT_SEARCH_HANDLER ],
    ["date", "Date", lambda { |fieldname, params, query| 
        return "#{fieldname} like '%#{params[fieldname].gsub('-', '').gsub('/', '')}%'"
      }
    ],
    ["author", "Author", A_DEFAULT_SEARCH_HANDLER],
    ["selling_agent", "Selling Agent", lambda { |fieldname, params, query| 
        return "source_agents.role = \"#{SourceAgent::ROLE_SELLING_AGENT}\" AND names.name like '%#{params[fieldname]}%'"
      },
      lambda { |query|  return query.joins(source_agents: [ :agent] ) }
    ],
    ["institution", "Institution", lambda { |fieldname, params, query| 
        return "source_agents.role = \"#{SourceAgent::ROLE_INSTITUTION}\" AND names.name like '%#{params[fieldname]}%'"
      },
      lambda { |query|  return query.joins(source_agents: [ :agent] ) }
    ]
  ]

  def new
    @source = Source.new
    respond_to do |format|
      format.html { render "edit" }
    end
  end

#  def index
#    @search_fields = SEARCH_FIELDS
#  end

  def create
    filtered = source_params_for_create_and_edit
    @source = Source.new(filtered)
    if @source.whether_mss == Source::TYPE_HAS_MANUSCRIPT_NO
      @source.status = Source::TYPE_STATUS_NO_MSS
    else
      @source.status = Source::TYPE_STATUS_TO_BE_ENTERED
    end
    success = @source.save_by(current_user)
    respond_to do |format|
      format.json {
        if !success
          errors_data = @source.errors.messages
          render :json => { :errors => errors_data }, :status => :unprocessable_entity
        else
          render "show"
        end
      }
      format.html {
        render "show"
      }
    end
  end

  def edit
  end

  def update
    success = false
    ActiveRecord::Base.transaction do
      filtered = source_params_for_create_and_edit
      success = @source.update_by(current_user, filtered)
    end
    respond_to do |format|
      format.json {
        if !success
          errors_data = @source.errors.messages
          render :json => { :errors => errors_data }, :status => :unprocessable_entity
        else
          render "show"
        end
      }
      format.html {
        render "edit"
      }
    end
  end

  # TODO: this is kinda slow and needs to be optimized
  def similar
    get_similar

    respond_to do |format|
      format.json
    end
  end

  def model_class
    Source
  end

  def search_name_field
    "title"
  end

  def search_exact_enabled
    false
  end

  def search_query_base
    search_model_class.all.includes([:created_by])
  end

  def search_query
    query = super

    if params["from"] && params["to"]
      # handle range of IDs for a 'Jump To' search
      query = query.where("id >= ? and id <= ?", params["from"], params["to"])
    elsif params["agent"]
      # handle queries for either Institution or Selling Agent (this
      # happens from the Add New Entry workflow)
      query = query.joins(source_agents: [ :agent ] ).where('names.name like ?', "%#{params["agent"]}%")
    end
    
    queries = []

    j = params['op'] && params['op'] == 'OR' ? " OR " : " AND "
    # always process these fields (used on both Add New Entry workflow and
    # Manage Sources screen)
    A_SEARCH_FIELDS.each do |field|
      fieldname = field[0]
      handler = field[2]
      # modified to handle multiple field names, again, as in advanced search
      if params[fieldname].present?
        if field[3]
          query = field[3].call(query)
        end
        if params[fieldname].kind_of? Array
          params[fieldname].each do |q|
            p = params.dup
            p[fieldname] = q
            queries += [handler.call(fieldname, p, query)]
          end
        else
          queries  += [handler.call(fieldname, params, query)]
        end
      end
    end
    query.where(queries.join(j)).with_associations
#    query.with_associations
  end

  def search_results_order
    if params["order"]
      return [ search_model_class.to_s.underscore.pluralize + "." + params["order"] ]
    else
      return ["date desc", "title"]
    end
  end

  def search_result_format(obj)
    {
      id: obj.id,
      date: SDBMSS::Util.format_fuzzy_date(obj.date),
      source_type: obj.source_type.display_name,
      entries_count: obj.entries_count || 0,
      title: obj.title,
      display_value: obj.display_value,
      author: obj.author,
      selling_agent: (selling_agent = obj.get_selling_agent_as_name).present? ? selling_agent.name : "",
      institution: (institution_agent = obj.get_institution_as_name).present? ? institution_agent.name : "",
      whether_mss: obj.whether_mss,
      medium: obj.medium_for_display,
      date_accessed: obj.date_accessed,
      location_institution: obj.location_institution,
      location: obj.location,
      link: obj.link,
      comments: obj.comments,
      created_by: obj.created_by.present? ? obj.created_by.username : "(none)",
      created_at: obj.created_at.present? ? obj.created_at.to_formatted_s(:long) : "",
      updated_by: obj.updated_by.present? ? obj.updated_by.username : "(none)",
      updated_at: obj.updated_at.present? ? obj.updated_at.to_formatted_s(:long) : ""
    }
  end

  # change the status of a Source
  def update_status
    new_status = params[:status]
    error = nil
    if Source::STATUS_TYPES.map(&:first).member? new_status
      @source.status = new_status
      @source.save
    else
      error = "Invalid status"
    end

    respond_to do |format|
      format.html {
        if error.blank?
          render nothing: true
        else
          render status: :unprocessable_entity, html: "Invalid status"
        end
      }
      format.json {
        if error.blank?
          render nothing: true
        else
          render status: :unprocessable_entity, json: { "errors" => { base: "Invalid status" } }
        end
      }
    end
  end

  # returns JSON containing type constants
  def types
    data = {
      'source_type' => SourceType.all.map { |source_type|
        hash = source_type.attributes
        hash['invalid_source_fields'] = Source.invalid_source_fields_for_source_type(source_type.name)
        hash['valid_roles_for_source_agents'] = SourceAgent.valid_roles_for_source_type(source_type.name)
        hash
      },
      'medium' => Source::MEDIUM_TYPES,
    }

    respond_to do |format|
      format.json {
        render json: data
      }
    end
  end

  def merge
    @source = Source.find(params[:id])
    @target_id = params[:target_id]
    @target = nil
    params[:title] = @source.title
    params[:date] = @source.date
    get_similar 
    if @target_id.present?
      if @target_id.to_i == @source.id
        @warning = "You can't merge a record into itself"
      elsif Source.find_by(id: @target_id).source_type != @source.source_type
        @warning = "You can only merge sources that are the same type, to avoid data loss"
      else
        @target = Source.find_by(id: @target_id)
      end
    end
    if params[:confirm] == "yes"
      @source.merge_into(@target)
      render "merge_success"
    end
  end

  # we don't ever destroy anything, we just mark it as deleted
  def destroy
    error = nil
    if @source.entries_count.to_i == 0
      @source.deleted = true
      if !@source.save_by(current_user)
        error = @source.errors.to_s
      end
    else
      error = "Can't mark a source as deleted if it has entries"
    end

    # if we call respond_with(@entry), which is more rails-ish, the
    # response is a 302 to a #show, but jquery's ajax code gets stuck
    # in an redirect loop, deleting the object over and over again. So
    # we force-return a 200 with an empty body for JSON calls to this
    # action.
    respond_to do |format|
      format.json {
        if !error
          render :json => {}, :status => :ok
        else
          render status: :unprocessable_entity, json: { "error" => error }
        end
      }
    end
  end

  def conflict
    get_conflicts

    respond_to do |format|
      format.json
    end
  end

  private

# FIX ME: how to get similar before it exists?!  right now uses levenshtein for that, solr for everything else

  def get_similar
    type = @source.source_type_id || 99
    s = Sunspot.more_like_this(@source) do
      fields :title, :date
      with :source_type_id, type
      paginate page: 1, per_page: 10
      order_by :score, :desc
    end
    @similar = s.results
  end

  def get_conflicts
    filtered = source_params_for_create_and_edit
    title = filtered['title']
    date = filtered['date']

    query = Source.none

    if date.present? || title.present?
      query = Source.all

      if date.present?
        # use only the year so we get broadest possible matches
        broad_date = date.dup
        broad_date = broad_date[0..3] if broad_date.length > 4
        query = query.where("date LIKE '#{broad_date}%'")
      end

      if title.present?
        # NOTE: the order in which we add criteria to query seems to
        # make a difference in performance.

        # remove leading and trailing quotation marks and apostrophes
        words = title.split.select { |word| word.length > 3 }.map { |word| word.gsub(/^['"]/, '').gsub(/['"]$/, '') }

        words = words.map { |word| word.gsub(/"/, '\"') }

        # find titles that have ANY words in new title
        query = query.where(words.map { |word| "title LIKE \"%#{word}%\"" }.join(" OR "))

        # whittle them down by string similarity
        len = title.length
        query = query.where("length(title) <= #{len+8} AND length(title) >= #{len-8} AND levenshtein_ratio(title, ?) <= 40", title)
      end

      query = query.limit(5)
    end

    @similar = query
  end

  def set_source
    @source = Source.find(params[:id])
  end

  def source_params
    params.require(:source)
  end

  def params_for_search
    # agent_name can come from a number of sources
    # FIX ME: maybe we want to only search for selling agents though?
    params[:agent_name] = Array(params[:agent]) + Array(params[:selling_agent]) + Array(params[:institution])
    params.permit(:title, {:title => []}, :author, {:author => []}, :agent_name, {:agent_name => [] }, :location_institution, :medium, :date, {:date => []})
  end

  def filters_for_search
#    params.permit(:agent_name)
  end

  def source_params_for_create_and_edit
    # Note that we don't call require(:source), which is the typical
    # Rails convention, because Rails' wrapped parameters feature
    # doesn't pick up the *_attributes fields that way.
    params.permit(
      :source_type_id,
      :date,
      :title,
      :author,
      :whether_mss,
      :medium,
      :date_accessed,
      :location,
      :location_institution,
      :link,
      :comments,
      :status,
      :source_agents_attributes => [ :id, :agent_id, :role, :_destroy ],
    )
  end

end