class NotificationMailer < ApplicationMailer

  def welcome_email(user)
    @user = user
    @url = 'http://www.google.com'
    mail(to: @user.email, subject: "Welcome Email")
  end

  def notification_email(notification)
    @notification = notification
    @title = notification.title
    @user = notification.user
    mail(to: @user.email, subject: "SDBM: #{@title}")
  end

end
