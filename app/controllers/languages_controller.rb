class LanguagesController < ManageModelsController

  include LanguagesAndPlaces
  include MarkAsReviewed

  load_and_authorize_resource :only => [:edit, :update, :destroy, :mark_as_reviewed]

  def model_class
    Language
  end

end
