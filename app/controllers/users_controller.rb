
class UsersController < SimpleNamedModelsController

  before_action :require_admin, only: [:index]

  def model_class
    User
  end

  def search_name_field
    return "username"
  end

  private

  def require_admin
    authorize! :list, User
  end

end
