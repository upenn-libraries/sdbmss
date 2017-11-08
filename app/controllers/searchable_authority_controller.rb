class SearchableAuthorityController < ManageModelsController

  require 'csv'
  require 'rubygems'
  require 'zip'

  def create
    #ActiveRecord::Base.transaction do
      super
    #  @transaction_id = PaperTrail.transaction_id
    #end
    if @model.id
      @model.delay.index
    end
  end

  def update
    #ActiveRecord::Base.transaction do
      super
    #  @transaction_id = PaperTrail.transaction_id
    #end
    @model.delay.index
  end

  def destroy
    super
#    @model.delay.index
  end

  def format_search(s)
    bookmarkable = [Source, Manuscript, Name].include? model_class
    results = s.results.map do |obj|
      if bookmarkable
        obj.search_result_format.merge({
          bookmarkwatch: (render_to_string partial: "nav/bookmark_watch_table", locals: {model: obj }, layout: false, formats: [:html]),  
          can_edit: can?(:edit, obj)
        })
      else
        obj.search_result_format
      end
    end
    respond_to do |format|
      format.json {
        render json: {
                 limit: s.results.count,
                 offset: s.results.offset,
                 total: s.total,
                 results: results,
               }
      }
      format.csv {
        make_csv(results, @d)
      }
    end
  end

  def index
    @search_fields = model_class.search_fields
    @fields = model_class.fields
    @filters = model_class.filters
    @dates = model_class.dates
    @filter_options = ["with", "without", "blank", "not blank", "less than", "greater than"]
    @field_options = ["contains", "does not contain", "blank", "not blank", "before", "after"]
    @date_options = ["before", "after", "near", "exact"]    
  end

  def search
    if params[:created_by_user].to_i == 1
      params.merge!({created_by: current_user.username})
    end
    if params[:format] == 'csv'
      if current_user.downloads.count >= 5
        render json: {error: 'at limit'}
        return
      end
      @d = Download.create({filename: "#{search_model_class.to_s.downcase.pluralize}.csv", user_id: current_user.id})
      respond_to do |format|
        format.csv {
          render json: {id: @d.id, filename: @d.filename, count: current_user.downloads.count}
        }
      end
      model_class.delay.do_csv_search(params, @d) 
    else
      s = model_class.do_search(params)
      format_search s
    #do_search(params)
    end
  end

  def get_similar
    s = Sunspot.more_like_this(@model) do
      fields :name
      paginate page: 1, per_page: 10
      order_by :score, :desc
    end
    @similar = s.results
  end

  def more_like_this
    n = model_class.new(name: params[:name])
    n.index!
    s = n.more_like_this do
      fields :name
      paginate page: params[:page], per_page: 10
      order_by :score, :desc
    end
    results = s.results
    respond_to do |format|
      format.json { render :json => {results: results, status: :ok}}
    end
    n.remove_from_index
  end

end