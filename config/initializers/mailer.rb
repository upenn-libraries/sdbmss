if Rails.env.development?

  ActionMailer::Base.raise_delivery_errors = true

  #fix me: even though this is on development, use ENV for email/password
  ActionMailer::Base.smtp_settings = {
    :address => "smtp.gmail.com",
    :port => 587,
    :authentication => :plain,
    :domain => 'localhost',
    :user_name => 'sdbmssdev@gmail.com',
    :password => 'xsw23edC',
    :enable_starttls_auto => true
  }

end