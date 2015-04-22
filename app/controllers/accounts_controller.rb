
# We have an 'Accounts' resource b/c devise uses 'Users' by default
# and combining all the stuff we want to be able to do with User
# models into a single controller makes things hairy.
class AccountsController < SimpleNamedModelsController

  before_action :require_admin

  def model_class
    User
  end

  def search_model_class
    User
  end

  def resource_name
    "accounts"
  end

  def search_name_field
    return "username"
  end

  private

  # override from SimpleNamedModelsController: use profile#show
  def model_path(id)
    profile_path(@model.username)
  end

  def require_admin
    authorize! :list, User
  end

  def model_params
    params.require(model_class_lstr.to_sym).permit(:username, :email, :email_is_public, :password, :password_confirmation, :role, :bio)
  end

end
