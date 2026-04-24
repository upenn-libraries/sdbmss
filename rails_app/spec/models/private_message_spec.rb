require "rails_helper"

describe PrivateMessage do

  let(:sender)    { create(:user) }
  let(:recipient) { create(:user) }

  def build_message(attrs = {})
    PrivateMessage.new(
      { title: "Hello", message: "A short message", created_by: sender }.merge(attrs)
    )
  end

  def create_message(attrs = {})
    pm = build_message(attrs)
    pm.save!(validate: false)
    pm
  end

  describe "#sent_by" do
    context "when created_by is set" do
      it "returns the creator" do
        pm = build_message
        expect(pm.sent_by).to eq(sender)
      end
    end
  end

  describe "#unread" do
    context "when a UserMessage exists for the user" do
      it "returns the unread flag value" do
        pm = create_message
        UserMessage.create!(private_message: pm, user: recipient, unread: true)
        expect(pm.unread(recipient)).to eq(true)
      end

      it "returns false when the message has been read" do
        pm = create_message
        UserMessage.create!(private_message: pm, user: recipient, unread: false)
        expect(pm.unread(recipient)).to eq(false)
      end
    end

    context "when no UserMessage exists for the user" do
      it "returns false" do
        pm = create_message
        expect(pm.unread(recipient)).to eq(false)
      end
    end
  end

  describe "#read" do
    context "when a UserMessage exists for the user" do
      it "marks the message as read and returns truthy" do
        pm = create_message
        um = UserMessage.create!(private_message: pm, user: recipient, unread: true)
        result = pm.read(recipient)
        expect(result).to be_truthy
        expect(um.reload.unread).to eq(false)
      end
    end

    context "when no UserMessage exists for the user" do
      it "returns false" do
        pm = create_message
        expect(pm.read(recipient)).to eq(false)
      end
    end
  end

  describe "#preview" do
    it "includes the title and short message" do
      pm = build_message(title: "Subject", message: "Brief")
      expect(pm.preview).to include("Subject")
      expect(pm.preview).to include("Brief")
    end

    it "truncates messages longer than 100 characters with an ellipsis" do
      long_body = "x" * 120
      pm = build_message(message: long_body)
      expect(pm.preview).to include("...")
    end

    it "does not add ellipsis for messages 100 characters or fewer" do
      pm = build_message(message: "a" * 100)
      expect(pm.preview).not_to include("...")
    end
  end

end
