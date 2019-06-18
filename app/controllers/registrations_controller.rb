class RegistrationsController < Devise::RegistrationsController
  protected

  invisible_captcha only: [:create], honeypot: :fullname

  def after_sign_up_path_for(resource)
    User.where(role: 'admin').each do |user|
      user.notify("A new user has been created", resource, "new_user")
    end

    if User.exists?(2)
      p = PrivateMessage.create!(title: "Welcome to the Schoenberg Database!",
        message: %Q(
        <p>Welcome to the Schoenberg Database, <b>#{resource.to_s}</b>! You have joined a collaborative network of manuscript enthusiasts dedicated to capturing and analyzing manuscript data. We are so delighted that you joined us!</p>
        
        <p>You can learn all about the history and mission of the database by reading through the content in the About menu at the top right of your screen. Be sure to consult the Help content for instructional material. Our video tutorials offer quick demonstrations of the major database tasks. You will also find instructions throughout the website as you search for manuscripts and enter data. Use the Submit Feedback link to contact us with any questions, or to share information about your own research.</p>       
        
        <p>Sincerely,</p>
        
        <p>The SDBM Project Team</p>       
        
        <p>Lynn Ransom - Project Manager</p>
        <p>Benny Heller - Programmer Analyst</p>
        <p>Emma Cawlfield - Project Coordinator</p>
        ),
        created_by: User.find(2) # 12-06-17 fix me: this feels a little iffy, maybe set the user account from ENV_VARIABLE?
      )
      UserMessage.create!(private_message: p, user: resource)
      resource.notify("You have a new message.", p, "message")
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

  def after_update_path_for(resource)
    profile_path(resource.username)
  end

end