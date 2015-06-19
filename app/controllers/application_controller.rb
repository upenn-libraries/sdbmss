class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller 
  include Blacklight::Controller
  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  layout 'application'

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :configure_permitted_parameters, if: :devise_controller?

  before_action :expire_login_page, if: :devise_controller?

  rescue_from CanCan::AccessDenied, with: :render_access_denied

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation, :remember_me) }
    devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me) }
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:username, :email, :email_is_public, :fullname, :institutional_affiliation, :password, :password_confirmation, :current_password, :bio) }
  end

  # used by devise
  def after_sign_in_path_for(resource)
    return dashboard_path
  end

  def expire_login_page
    # expire the login page, otherwise users can back button to it and
    # use an expired CSRF token, raising
    # ActionController::InvalidAuthenticityToken exceptions
    if controller_name == "sessions" && action_name == "new"
      response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    end
  end

  def render_404
    respond_to do |format|
      format.html { render :file => "#{Rails.root}/public/404", :layout => false, :status => :not_found }
      format.xml  { head :not_found }
      format.any  { head :not_found }
    end
  end

  def render_access_denied
    respond_to do |format|
      format.html { render :template => "errors/access_denied", :status => 403 }
    end
    true
  end

end
