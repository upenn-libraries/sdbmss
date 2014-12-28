
# Adds a 'search' method to a standard resource controller
module ResourceSearch

  extend ActiveSupport::Concern

  def search
    class_name = send(:class).to_s.sub('Controller', '').singularize.constantize
    objects = []
    search_term = params[:term]
    if search_term.present?
      objects = class_name.where('name like ?', "%#{search_term}%").map do |obj|
        { id: obj.id, display_value: "#{obj.name} (ID: #{obj.id})" }
      end
    end
    respond_to do |format|
      format.json { render json: objects }
    end
  end

end
