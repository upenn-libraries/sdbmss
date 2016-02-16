class SearchableAuthorityController < ManageModelsController

  def create
    super
    @model.delay.index
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

  def search

    order = params[:order].present? ? {field: params[:order].split[0], direction: params[:order].split[1]} : {}
    limit = params[:limit].present? ? params[:limit].to_i : 50
    page = params[:limit] ? (params[:offset].to_i / params[:limit].to_i) + 1 : 1
    op = params[:op].present? ? params[:op] : 'and'
    
    filters = filters_for_search
    params = params_for_search

    # FIX ME: need to add some way of doing 'or' searches .. again

    s = Sunspot.search model_class do
      
      if filters.present?
        filters.each do |field, value|
          width field, value
        end
      end

      if op == 'OR'
        any do
          if params.present?
            params.each do |field, value|
              if value.kind_of? Array
                value.each do |v|
                 fulltext v, :fields => [field]
                end
              else
               fulltext value, :fields => [field]
             end
            end
          end
        end
      else
        all do
          if params.present?
            params.each do |field, value|
              if value.kind_of? Array
                value.each do |v|
                 fulltext v, :fields => [field]
                end
              else
               fulltext value, :fields => [field]
             end
            end
          end
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
    params[:name] = params[:term]
    params.permit(:name)
  end

  def filters_for_search
    {}
  end

end