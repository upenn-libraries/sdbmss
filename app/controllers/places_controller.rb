class PlacesController < SearchableAuthorityController

  include LanguagesAndPlaces
  include MarkAsReviewed
  include LogActivity

  include Revert

  load_and_authorize_resource :only => [:edit, :update, :destroy, :mark_as_reviewed]

  def model_class
    Place
  end
end
