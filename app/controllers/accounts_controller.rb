
# We have an 'Accounts' resource b/c devise uses 'Users' by default
# and combining all the stuff we want to be able to do with User
# models into a single controller makes things hairy.
class AccountsController < SimpleNamedModelsController

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
      reviewed: obj.reviewed,
      created_by: obj.created_by.present? ? obj.created_by.username : "(none)",
    }
  end

  def search_query
    query = super
    if params[:unreviewed_only].to_s == '1'
      query = query.where(reviewed: false)
    end
    if params[:created_by_user].to_s == '1'
      query = query.where(created_by_id: current_user.id)
    end
    query
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
