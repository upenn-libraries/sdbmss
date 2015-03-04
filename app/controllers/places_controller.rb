class PlacesController < SimpleNamedModelsController

  def model_class
    Place
  end

  def search_results_keys
    [:id, :name, :entries_count]
  end

end
