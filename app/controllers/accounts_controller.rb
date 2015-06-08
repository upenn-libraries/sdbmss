
# We have an 'Accounts' resource b/c devise uses 'Users' by default
# and combining all the stuff we want to be able to do with User
# models into a single controller makes things hairy.
class AccountsController < ManageModelsController

  include MarkAsReviewed

  before_action :require_admin

  def model_class
    User
  end

  def search_model_class
    User
  end

  def search_result_format(obj)
    {
      id: obj.id,
      username: obj.username,
      active: obj.active,
      reviewed: obj.reviewed,
      created_by: obj.created_by.present? ? obj.created_by.username : "(none)",
    }
  end

  def resource_name
    "accounts"
  end

  def search_name_field
    return "username"
  end

  private

  # override from ManageModelsController: use profile#show
  def model_path(id)
    profile_path(@model.username)
  end

  def require_admin
    authorize! :manage, User
  end

  def model_params
    params.require(model_class_lstr.to_sym).permit(:username, :fullname, :email, :email_is_public, :password, :password_confirmation, :role, :bio, :active)
  end

end
