require 'rails_helper'

RSpec.describe FeedbackMailer, type: :mailer do
  describe "feedback_email" do
    let(:from) { "user@example.com" }
    let(:subject_text) { "Test Subject" }
    let(:body) { "Test Body" }
    let(:mail) { FeedbackMailer.feedback_email(from, subject_text, body) }

    before do
      allow(ENV).to receive(:fetch).with('SDBMSS_EMAIL_FROM').and_return('admin@example.com')
    end

    it "renders the headers" do
      expect(mail.subject).to eq("Feedback from New SDBM Website: Test Subject")
      expect(mail.to).to eq(["admin@example.com"])
      expect(mail.from).to eq(["user@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match(body)
    end
  end
end
