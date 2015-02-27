class LanguagesController < SimpleNamedModelsController

  def model_class
    Language
  end

  def search_results_map(results)
    ids = results.map { |h| h[:id] }
    counts = model_class.joins(:entry_languages).where(id: ids).group("languages.id").count("entry_languages.id")
    results.each { |h| h[:count] = counts[h[:id]] || 0 }
  end

end
