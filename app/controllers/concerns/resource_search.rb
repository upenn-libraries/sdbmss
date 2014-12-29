
# Adds a 'search' method to a standard resource controller
module ResourceSearch

  extend ActiveSupport::Concern

  def max_search_results
    25
  end

  def search
    class_name = send(:class).to_s.sub('Controller', '').singularize.constantize
    objects = find_by_search_terms(class_name).limit(max_search_results).map do |obj|
      { id: obj.id, display_value: "#{display_value_for_search(obj)} (ID: #{obj.id})" }
    end
    respond_to do |format|
      format.json { render json: objects }
    end
  end

  # Classes that include this module should override this if they
  # need to search differently
  def find_by_search_terms class_name
    search_term = params[:term]
    if search_term.present?
      class_name.where('name like ?', "%#{search_term}%")
    else
      class_name.none
    end
  end

  # Returns a str to use for the 'display_value' field of the JSON
  # representation of passed-in object
  def display_value_for_search obj
    "#{obj.name}"
  end

end
