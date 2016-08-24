
class RegistrationsController < Devise::RegistrationsController
  protected

  def after_sign_up_path_for(resource)
    return edit_user_registration_path
  end

end
