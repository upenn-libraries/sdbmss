
# Provides search functionality for entities in a standard Rails
# resource controller. This is designed to allow overriding of various
# methods to custom tailor various parameters and behaviors.
#
# Accepts the following certain URL parameters: term, limit, offset,
# order, order_dir
#
# This is used by autocomplete as well as to load tables via AJAX in
# the management screens for some entities.
module ResourceSearch

  extend ActiveSupport::Concern

  def search_results_limit
    params["limit"]
  end

  def search_results_offset
    params["offset"]
  end

  def search_results_order
    [params["order"] || "name asc"]
  end

  # Returns the constant of the Model handled by this controller.
  # Classes should override this if the name of the controller doesn't
  # conform to the Rails convention of 'ModelController'.
  def search_model_class
    send(:class).to_s.sub('Controller', '').singularize.constantize
  end

  # Classes should override this is they want to return a different
  # set of keys for each result object. Used by the default
  # implementation of #search_results_format.
  def search_results_keys
    [:id, :name]
  end

  # Formats the passed-in search result object, returning it as a hash.
  # This default implementation uses #search_results_keys.
  def search_result_format(obj)
    result = Hash.new
    search_results_keys.each do |key|
      result[key] = obj.send key
    end
    result
  end

  # Classes can override this to modify the results with additional
  # attributes. 'results' is an Array of Hashes of results that have
  # already been offset/limited/ordered.
  def search_results_map(results)
    # by default, don't do anything to results
    results
  end

  # Main callpoint: this should be exposed in routes
  def search
    query = search_query
    total = query.count

    query = query.order(*search_results_order) if search_results_order
    query = query.offset(search_results_offset) if search_results_offset
    query = query.limit(search_results_limit) if search_results_limit
    objects = query.map do |obj|
      search_result_format(obj)
    end
    objects = search_results_map(objects)
    respond_to do |format|
      format.json {
        render json: {
                 limit: search_results_limit,
                 offset: search_results_offset,
                 total: total,
                 results: objects,
               }
      }
      format.csv {
        headers = objects.first.keys
        formatter = Proc.new do |object|
          headers.map { |key| object[key] }
        end
        render csv: objects,
               filename: "#{search_model_class.to_s.downcase.pluralize}.csv",
               headers: headers,
               format: formatter
      }
    end
  end

  # Classes should override this if they need to search differently.
  # This should return an ActiveRecord query, on which
  # offseting/limiting/ordering will subsequently be done.
  #
  # This implementation looks at 'term' param, splits it, and searches
  # 'name' model field for its parts. If any integers are present, it
  # looks for them in the 'id' model field.
  def search_query
    search_term = params[:term]
    query = search_model_class.all
    if search_term.present?
      search_term.split.each do |word|
        # look at ID column for integers
        if !SDBMSS::Util.int?(word)
          query = query.where('name like ?', "%#{word}%")
        else
          query = query.where('name like ? or id = ?', "%#{word}%", word.to_s)
        end
      end
    end
    query
  end

end
