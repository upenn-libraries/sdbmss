class ApplicationMailer < ActionMailer::Base
  default from: "sdbmssdev@gmail.com" #fix me: use ENV for email-from
  layout 'mailer'
end
