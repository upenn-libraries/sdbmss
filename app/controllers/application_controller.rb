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

  helper_method :sdbmss_search_action_path

  # register user activity
  after_filter :user_activity

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation, :remember_me) }
    devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me) }
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:username, :email, :email_is_public, :fullname, :institutional_affiliation, :password, :password_confirmation, :current_password, :bio, :notification_setting_attributes => [:on_update, :on_comment, :on_reply, :on_message, :on_new_user, :on_all_comment, :on_group, :email_on_new_user, :email_on_update, :email_on_comment, :email_on_reply, :email_on_message, :email_on_all_comment, :email_on_group]) }
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
      format.json { render json: {error: 'access denied'}}
    end
    true
  end

  # This generates a consistent path for the search URL and should be
  # used in place of Blacklight's #search_action_path which makes a
  # contextually determined path. The latter breaks the top nav search
  # box on any page that uses a controller besides CatalogController.
  def sdbmss_search_action_path(options = {})
    opts = options.dup
    # prevent deprecation warnings from Rails
    ["action", "controller"].each do |key|
      if opts.has_key? key
        opts[key.to_s] = opts[key]
        opts.delete key
      end
    end
    root_path({ "utf8" => SDBMSS::Util::CHECKMARK, "search_field" => "all_fields" }.merge(opts))
  end

  private

  def user_activity
    current_user.try :touch
  end

end
