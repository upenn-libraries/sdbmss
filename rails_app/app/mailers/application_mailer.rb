class ApplicationMailer < ActionMailer::Base
  if Rails.env.development?
    default from: "sdbmssdev@gmail.com"
  else
    default from: ENV.fetch('SDBMSS_EMAIL_FROM')
  end
  layout 'mailer'
end
