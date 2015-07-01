
class FeedbackController < ApplicationController

  def send_email
    subject = params['subject']
    message = params['message']

    if subject.present? && message.present?
      from = ENV.fetch('SDBMSS_EMAIL_FROM')
      if params['anonymous'] != "1"
        if current_user.present? && current_user.email.present?
          from = current_user.email
        end
      end
      FeedbackMailer.feedback_email(from, subject, message)
      redirect_to :action => "thanks"
    else
      respond_to do |format|
        format.html {
          @errors = [ "Subject and message are required."]
          render "index"
        }
      end
    end
  end

  def thanks
  end

end
