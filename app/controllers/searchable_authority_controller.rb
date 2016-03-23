class SearchableAuthorityController < ManageModelsController

  SEARCH_FIELDS = ["name", "id", "created_by", "updated_by"]

  def create
    super
    if @model.id
      @model.delay.index
    end
  end

  def update
    super
    @model.delay.index
  end

  def destroy
    super
    @model.delay.index
  end

  def format_search(s)
    results = s.results.map do |obj|
      search_result_format(obj)
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
        headers = results.first.keys
        formatter = Proc.new do |object|
          headers.map { |key| object[key] }
        end
        render csv: results,
               filename: "#{search_model_class.to_s.downcase.pluralize}.csv",
               headers: headers,
               format: formatter
      }
    end
  end

  def index
    @search_fields = SEARCH_FIELDS
    @search_options = ["with", "without"]
  end

  def search

    order = params[:order].present? ? {field: params[:order].split[0], direction: params[:order].split[1]} : {}
    limit = params[:limit].present? ? params[:limit].to_i : 50
    page = params[:limit] ? (params[:offset].to_i / params[:limit].to_i) + 1 : 1
    op = params[:op].present? ? params[:op] : 'and'

    options = options_for_search

    filters = filters_for_search
    params = params_for_search

    puts "bah: #{filters}, #{params}"

    s = Sunspot.search model_class do
      
      fulltext_search = lambda { |p, o| 
        if params.present?
          p.each do |field, value|
            value = Array(value)
            if value.kind_of? Array
              value.each do |v|
                op = Array(options[field + "_option"]).shift
                # if searching for this 'without' the term, right now just add a '-' to the beginning of query to negate it
                if op && op == 'without'
                  fulltext "-" + v, :fields => [field]
                else
                  fulltext v, :fields => [field]
               end
              end
           end
          end
        end
      }

      if filters.present?
        filters.each do |field, value|
          op = Array(options[field + "_option"]).shift
            if value.kind_of?(Array) && value.all? { |v| v.blank? } # make sure it's not an array of blanks 
            elsif op && op == 'without'
              without field, value
            else
              with field, value
            end
        end
      end

      if op == 'OR'
        any do
          fulltext_search.call(params, options)
        end
      else
        all do
          fulltext_search.call(params, options)
        end
      end

      paginate :per_page => limit, :page => page
      order.present? ? order_by(order[:field], order[:direction]) : order_by(:score, :desc)
    end
    #s.results
    format_search s
  end

  def get_similar
    s = Sunspot.more_like_this(@model) do
      fields :name
      paginate page: 1, per_page: 10
      order_by :score, :desc
    end
    @similar = s.results
  end

  private

  def params_for_search
    params.permit(:name, {:name => []})
  end

  def filters_for_search
    params.permit(:id, :created_by, :updated_by, {:id => []}, {:created_by => []}, {:updated_by => []})
  end

  # permit as options fields with the format SEARCHFIELD_option
  def options_for_search
    params.permit(SEARCH_FIELDS.map do |s| {s + "_option" => []} end, SEARCH_FIELDS.map do |s| s + "_option" end)
  end 
end