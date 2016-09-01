class LanguagesController < SearchableAuthorityController

  include LanguagesAndPlaces
  include MarkAsReviewed
  include LogActivity

  include Revert

  load_and_authorize_resource :only => [:index, :edit, :update, :destroy, :mark_as_reviewed]

  def model_class
    Language
  end

end
