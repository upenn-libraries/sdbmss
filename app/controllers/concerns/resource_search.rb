
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
    params["limit"] || 25
  end

  def search_results_offset
    params["offset"] || 0
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
    query = query.order(*search_results_order)
    total = query.count
    objects = query.offset(search_results_offset).limit(search_results_limit).map do |obj|
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
    end
  end

  # Classes should override this if they need to search differently.
  # This should return an ActiveRecord query, on which
  # offseting/limiting/ordering will subsequently be done.
  def search_query
    search_term = params[:term]
    query = search_model_class.all
    if search_term.present?
      search_term.split.each do |word|
        query = query.where('name like ?', "%#{word}%")
      end
    end
    query
  end

end
