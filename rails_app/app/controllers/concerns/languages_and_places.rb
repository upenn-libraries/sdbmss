
# Languages and Places are almost identical, so we factor out some of
# the controller methods in common here.
module LanguagesAndPlaces

  extend ActiveSupport::Concern

  def search_query_base
    model_class.all.includes([:created_by])
  end

end
