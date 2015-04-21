
class UsersController < SimpleNamedModelsController

  before_action :require_admin, only: [:index]

  def model_class
    User
  end

  def search_name_field
    return "username"
  end

  def show
    @user = @model
  end

  private

  # # for nicer URLs, use username as the id key
  # def set_model
  #   @model = model_class.find_by(username: params[:id])
  # end

  def require_admin
    authorize! :list, User
  end

  def model_params
    params.require(model_class_lstr.to_sym).permit(:username, :email, :email_is_public, :bio)
  end

end
