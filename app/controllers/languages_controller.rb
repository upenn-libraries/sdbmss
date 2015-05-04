class LanguagesController < SimpleNamedModelsController

  include LanguagesAndPlaces

  load_and_authorize_resource :only => [:edit, :update, :destroy]

  def model_class
    Language
  end

end
