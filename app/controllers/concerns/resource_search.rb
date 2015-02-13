
# Adds a 'search' method to a standard resource controller
module ResourceSearch

  extend ActiveSupport::Concern

  def max_search_results
    25
  end

  # Classes should override this is they want to return a different
  # set of keys for each result object
  def search_results_keys
    [:id, :name]
  end

  def search
    class_name = send(:class).to_s.sub('Controller', '').singularize.constantize
    objects = find_by_search_terms(class_name).limit(max_search_results).map do |obj|
      result = Hash.new
      search_results_keys.each do |key|
        result[key] = obj.send key
      end
      result
    end
    respond_to do |format|
      format.json { render json: objects }
    end
  end

  # Classes that include this module should override this if they
  # need to search differently
  def find_by_search_terms class_name
    search_term = params[:term]
    query = class_name.all
    if search_term.present?
      search_term.split.each do |word|
        query = query.where('name like ?', "%#{word}%")
      end
    else
      query = class_name.none
    end
    query.order(:name)
  end

end
