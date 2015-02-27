class PlacesController < SimpleNamedModelsController

  def model_class
    Place
  end

  def search_results_map(results)
    ids = results.map { |h| h[:id] }
    counts = model_class.joins(:entry_places).where(id: ids).group("places.id").count("entry_places.id")
    results.each { |h| h[:count] = counts[h[:id]] || 0 }
  end

end
