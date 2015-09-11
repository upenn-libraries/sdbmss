
class FeedbackMailer < ActionMailer::Base

  def feedback_email(from, subject, body)
    @body = body
    to = ENV.fetch('SDBMSS_EMAIL_EXCEPTIONS_TO')
    mail(from: from, to: to , subject: "Feedback from New SDBM Website: #{subject}")
  end

end
