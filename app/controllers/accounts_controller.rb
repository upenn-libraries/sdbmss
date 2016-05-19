
# We have an 'Accounts' resource b/c devise uses 'Users' by default
# and combining all the stuff we want to be able to do with User
# models into a single controller makes things hairy.
class AccountsController < SearchableAuthorityController

  include MarkAsReviewed
  include LogActivity

  before_action :require_admin

  def search_fields
    super
    @fields.delete('name')
    @fields = ['username'] + @fields + ['fullname', 'email', 'role']
    @filters += ['active']
    @filters.delete('created_by')
    @filters.delete('updated_by')
    @fields + @filters + @dates
  end

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
      fullname: obj.fullname,
      role: obj.role,
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

  def login_as
    if current_user.role == 'admin'
      user = User.find_by(username: params[:username])
      if user.present?
        sign_in(:user, user)
        redirect_to dashboard_path
      else
        render body: "ERROR: User not found: #{params[:username]}"
      end
    else
      render :status => :forbidden
    end
  end

  def do_update
    if model_class.column_names.include?("encrypted_password") && model_params[:password].blank?
      result = @model.update_without_password(model_params)
      @model.updated_by = current_user
    else
      result = super
    end
    result
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
    params.require(model_class_lstr.to_sym).permit(:username, :fullname, :institutional_affiliation, :email, :email_is_public, :password, :password_confirmation, :role, :bio, :active)
  end

end
