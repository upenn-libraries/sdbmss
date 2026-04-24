require "rails_helper"

describe NotificationMailer do

  let(:user) { create(:user) }

  describe "#welcome_email" do
    subject(:mail) { described_class.welcome_email(user) }

    it "sends to the user's email address" do
      expect(mail.to).to include(user.email)
    end

    it "has the correct subject" do
      expect(mail.subject).to eq("Welcome Email")
    end
  end

  describe "#notification_email" do
    let(:notification) do
      double("Notification",
        title:    "New Activity",
        user:     user,
        notified: nil
      )
    end

    # The template renders edit_user_registration_url which requires a host.
    before { Rails.application.routes.default_url_options[:host] = "test.host" }
    after  { Rails.application.routes.default_url_options.delete(:host) }

    subject(:mail) { described_class.notification_email(notification) }

    it "sends to the notification user's email" do
      expect(mail.to).to include(user.email)
    end

    it "prefixes the title with SDBM: in the subject" do
      expect(mail.subject).to eq("SDBM: New Activity")
    end
  end

end
