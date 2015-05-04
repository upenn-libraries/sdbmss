class PlacesController < SimpleNamedModelsController

  include LanguagesAndPlaces

  load_and_authorize_resource :only => [:edit, :update, :destroy]

  def model_class
    Place
  end

end
