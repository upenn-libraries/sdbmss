class SearchableAuthorityController < ManageModelsController


  def search_fields
    @filters = ["id", "created_by", "updated_by"]
    @fields = ["name"]
    @dates = ["created_at", "updated_at"]
    @fields + @filters + @dates
  end

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
    @search_fields = search_fields
    @filter_options = ["present", "with", "without", "blank"]
    @field_options = ["contains", "does not contain", "blank", "present"]
    @date_options = ["before", "after", "near", "exact"]
    if params[:widescreen] == 'true'
      render :layout => 'widescreen'
    end
  end

  def search

    order = params[:order].present? ? {field: params[:order].split[0], direction: params[:order].split[1]} : {}
    limit = params[:limit].present? ? params[:limit].to_i : 50
    page = params[:limit] ? (params[:offset].to_i / params[:limit].to_i) + 1 : 1
    op = params[:op].present? ? params[:op] : 'and'

    options = options_for_search

    filters = filters_for_search
    params = params_for_search
    dates = dates_for_search

    s = Sunspot.search model_class do
      
      fulltext_search = lambda { |p, o| 
        if params.present?
          p.each do |field, value|
            value = Array(value)
            if value.kind_of? Array
              value.each do |v|
                op = Array(options[field + "_option"]).shift
                # if searching for this 'without' the term, right now just add a '-' to the beginning of query to negate it
                if op && op == 'does not contain'
                  fulltext "-" + v, :fields => [field]
                elsif op && op == 'blank'
                  with field, nil
                elsif op && op == 'present'
                  without field, nil
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
          value = Array(value)
          value.each do |v|
            op = Array(options[field + "_option"]).shift
            if op && op == 'blank'
              with field, nil
            elsif op && op == 'present'
              without field, nil
            elsif v.blank? # ignore blank
            elsif op && op == 'without'
              without field, v
            elsif v.kind_of?(Array) && v.all? { |v2| v2.blank? } # make sure it's not an array of blanks 
            else
              with field, v
            end
          end
        end
      end

      if dates.present?
        dates.each do |field, value|
          value = Array(value)
          value.each do |v|
            v = v.split(/[-\/]/).join("").ljust(8, '01')
            op = Array(options[field + "_option"]).shift
            # FIX ME: I used exception handling here because Date parsing for such varied input is awful - probably a better way
            begin
              if op && op == 'before'
                with(field).between(Date.new(0,1,1)..Date.parse(v))
              elsif op && op == 'after'
                with(field).between(Date.parse(v)..Date.today)
              elsif op && op == 'near'
                d = Date.parse(v)
                with(field).between((d - 1.month)..(d + 1.month))
              elsif op && op == 'exact'
                with(field, v)
              end
            rescue ArgumentError
              @error = "Error in Date Search - please use format YYYY/MM/DD or similar"
            end
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

  def dates_for_search
    params.permit(:created_at, :updated_at, {:created_at => []}, {:updated_at => []})
  end

  # permit as options fields with the format SEARCHFIELD_option
  def options_for_search
    params.permit(search_fields.map do |s| {s + "_option" => []} end, search_fields.map do |s| s + "_option" end)
  end 
end