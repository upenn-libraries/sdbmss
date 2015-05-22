
# Provides search functionality for entities in a standard Rails
# resource controller. This is designed to allow overriding of various
# methods to custom tailor various parameters and behaviors.
#
# Accepts the following certain URL parameters: term, limit, offset,
# order, order_dir, autocomplete (for autocomplete mode)
#
# This is used by autocomplete as well as the listings on the
# management screens. This maximizes code reuse, but on the flip side,
# the results returned are "full" records not well optimized for
# autocomplete. In practice, I don't think this matters: if it does,
# it speaks to the need to have separate controller actions for these
# 2 types of searches.
module ResourceSearch

  extend ActiveSupport::Concern

  def self.included(base)
    base.helper_method :search_name_field
  end

  def search_name_field
    "name"
  end

  def search_results_limit
    params["limit"]
  end

  def search_results_offset
    params["offset"]
  end

  def search_results_order
    [params["order"] || "#{search_name_field} asc"]
  end

  # Returns the constant of the Model handled by this controller.
  # Classes should override this if the name of the controller doesn't
  # conform to the Rails convention of 'ModelController'.
  def search_model_class
    self.class.to_s.sub('Controller', '').singularize.constantize
  end

  # Classes should override this is they want to return a different
  # set of keys for each result object. Used by the default
  # implementation of #search_results_format.
  def search_results_keys
    [:id, search_name_field.to_s]
  end

  # Formats the passed-in search result object, returning it as a hash.
  # This default implementation uses #search_results_keys.
  def search_result_format(obj)
    search_results_keys.reduce({ }) do |result, key|
      result[key] = obj.send key
      result
    end
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

    # in autocomplete mode, look for exact match so we can prepend it
    # if we need to
    exact = params[:autocomplete].present? ? search_exact : []

    query = search_query
    total = query.count

    query = query.order(*search_results_order) if search_results_order
    query = query.offset(search_results_offset) if search_results_offset
    query = query.limit(search_results_limit) if search_results_limit

    objects = query
    # prepend the exact match only if it's not in the normal results
    if exact.length > 0 && !query.any? { |result| search_exact_match(result) }
      objects = exact + objects
    end

    objects = objects.map do |obj|
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

  # Classes should override and return false to disable search_exact
  # behavior.
  def search_exact_enabled
    true
  end

  # Search for an exact match, which gets prepended to search results
  # list. This is so that autocomplete can show a result for an exact
  # match that may not appear in a search because it's too far down
  # the list.
  def search_exact
    exact = []
    search_term = params[:term] || ""
    if search_exact_enabled && search_term.length > 0
      exact = search_model_class.where("#{search_name_field} = ?", search_term)
    end
    exact
  end

  # returns true if this result is an exact match for search performed
  def search_exact_match(result)
    result.send(search_name_field.to_s) == params[:term]
  end

  # A 'base' query returning all records, to which search criteria are
  # applied. Subclasses can override this in order to tack on an
  # #includes for better performance.
  def search_query_base
    search_model_class.all
  end

  # Classes should override or extend this if they need to search
  # differently. This should return an ActiveRecord query.
  # Offseting/limiting/ordering should NOT be done here, only
  # filtering.
  #
  # This implementation looks at the followin params:
  #
  # 'term' = splits it, and searches 'name' model field for its
  # parts. If any integers are present, it looks for them in the 'id'
  # model field.
  def search_query
    query = search_query_base
    search_term = params[:term]
    if search_term.present?
      search_term.split.each do |word|
        # look at ID column for integers
        if !SDBMSS::Util.int?(word)
          query = query.where("#{search_name_field} like ?", "%#{word}%")
        else
          query = query.where("#{search_name_field} like ? or id = ?", "%#{word}%", word.to_s)
        end
      end
    end
    query
  end

end
