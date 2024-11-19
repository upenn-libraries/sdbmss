if Rails.env.development?

  ActionMailer::Base.raise_delivery_errors = true

  ActionMailer::Base.smtp_settings = {
    :address => "smtp.gmail.com",
    :port => 587,
    :authentication => :plain,
    :domain => 'localhost',
    :user_name => ENV.fetch('SDBMSS_NOTIFY_EMAIL'),
    :password => ENV.fetch('SDBMSS_NOTIFY_EMAIL_PASSWORD'),
    :enable_starttls_auto => true
  }

end