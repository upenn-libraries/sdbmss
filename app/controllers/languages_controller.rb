class LanguagesController < SimpleNamedModelsController

  def model_class
    Language
  end

  def search_results_keys
    [:id, :name, :entries_count]
  end

end
