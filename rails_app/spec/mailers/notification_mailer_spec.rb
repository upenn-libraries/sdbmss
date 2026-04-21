require 'rails_helper'

RSpec.describe NotificationMailer, type: :mailer do
  describe "welcome_email" do
    let(:user) { create(:user) }
    let(:mail) { NotificationMailer.welcome_email(user) }

    it "renders the headers" do
      expect(mail.subject).to eq("Welcome Email")
      expect(mail.to).to eq([user.email])
    end
  end

  describe "notification_email" do
    let(:notification) { create(:notification) }
    let(:mail) { NotificationMailer.notification_email(notification) }

    it "renders the headers" do
      expect(mail.subject).to eq("SDBM: #{notification.title}")
      expect(mail.to).to eq([notification.user.email])
    end
  end
end
