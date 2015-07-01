
class FeedbackMailer < ApplicationMailer

  def feedback_email(from, subject, body)
    @body = body
    to = "jeffchiu@upenn.edu" # ENV.fetch('SDBMSS_EMAIL_FROM')
    mail(from: from, to: to , subject: subject)
  end

end
