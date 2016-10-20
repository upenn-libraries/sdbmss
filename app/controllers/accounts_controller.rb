
# We have an 'Accounts' resource b/c devise uses 'Users' by default
# and combining all the stuff we want to be able to do with User
# models into a single controller makes things hairy.
class AccountsController < SearchableAuthorityController

  include MarkAsReviewed
  include LogActivity

  before_action :require_admin

  def model_class
    User
  end

  def resource_name
    "accounts"
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
    params.require(model_class_lstr.to_sym).permit(:username, :fullname, :institutional_affiliation, :email, :email_is_public, :password, :password_confirmation, :role, :bio, :active, :notification_setting_attributes => [:on_update, :on_comment, :on_reply, :on_message, :on_new_user, :on_comment, :email_on_new_user, :email_on_update, :email_on_comment, :email_on_reply, :email_on_message, :email_on_all_comment])
  end

end
