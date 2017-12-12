
# We have an 'Accounts' resource b/c devise uses 'Users' by default
# and combining all the stuff we want to be able to do with User
# models into a single controller makes things hairy.
class AccountsController < SearchableAuthorityController

  include MarkAsReviewed
  #include LogActivity
  include AddToGroup

  before_action :require_admin, only: [:index, :new, :create, :edit, :destroy, :login_as]

  def model_class
    User
  end

  def search_model_class
    User
  end

  def resource_name
    "accounts"
  end

  def login_as
    if can? :manage, User
      user = User.find_by(username: params[:username])
      if user.present?
        sign_in(:user, user)
        redirect_to dashboard_contributions_path
      else
        render body: "ERROR: User not found: #{params[:username]}"
      end
    else
      render :status => :forbidden
    end
  end

  # overrides the default 'add_to_group' (and remove) since this is the USER half of things; but otherwise it's the same
  def add_to_group
    ids = params[:ids]
    group = Group.find(params[:group_id])
    if ids.present?
      users = User.where(id: ids)
      users.each do |u|
        GroupUser.create(user: u, group: group, created_by: current_user)
        if current_user != u
          u.notify(
            "#{current_user.to_s} has added you to user group: #{group.name}",
            group, 
            "group"
          )
        else
          group.admin.each do |admin|
            admin.notify(
              "#{current_user.to_s} has requested to be added to the user group: #{group.name}",
              group,
              "group"
            )
          end
        end
      end
      if users.count === 1 && users.first === current_user
        flash[:notice] = "Request sent!"
      else
        flash[:notice] = "#{"Invitation".pluralize(users)} sent!"
      end
    end
    respond_to do |format|
      format.json { render :json => {}, :status => :ok }
      format.html {
        if users
          flash.now[:success] = "Group membership pending for #{users.map(&:username).join(', ')}."
        end        
        redirect_to group_path(group) 
      }
    end
  end

  def remove_from_group
    ids = params[:ids]
    group = Group.find(params[:group_id])
    group.group_users.where(:user_id => ids).destroy_all
    respond_to do |format|
      format.json { render :json => {}, :status => :ok }
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
    params.require(model_class_lstr.to_sym).permit(:username, :fullname, :institutional_affiliation, :email, :email_is_public, :password, :password_confirmation, :role, :bio, :active, :backup,
      :notification_setting_attributes => [
        :id, :user_id, :on_update, :on_comment, :on_reply, :on_message, :on_new_user, :on_group, :on_forum_post,
        :email_on_new_user, :email_on_update, :email_on_comment, :email_on_reply, :email_on_message, :email_on_group, :email_on_forum_post
        ]
      )
  end

end