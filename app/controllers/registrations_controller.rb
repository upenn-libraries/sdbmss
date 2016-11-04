
class RegistrationsController < Devise::RegistrationsController
  protected

  def after_sign_up_path_for(resource)
    User.where(role: 'admin').each do |user|
      user.notify("A new user has been created", resource, "new_user")
    end
    return edit_user_registration_path
  end

  def update_resource(resource, params)
    if params[:password].present?
      resource.update_with_password(params)
    else
      resource.update_without_password(params.except(:current_password))
    end
  end

end
