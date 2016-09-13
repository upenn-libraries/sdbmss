class NotificationMailer < ApplicationMailer

  def welcome_email(user)
    @user = user
    @url = 'http://www.google.com'
    mail(to: @user.email, subject: "Welcome Email")
  end

  def notification_email(notification)
    @title = notification.title
    @url = notification.url
    @message = notification.message
    @user = notification.user
    mail(to: @user.email, subject: @title)
  end

end
