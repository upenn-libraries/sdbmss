require "rails_helper"

RSpec.describe "Manage private messages", type: :request do
  let(:admin_user) { create(:admin) }

  describe "GET /private_messages" do
    it "redirects guests to sign in" do
      get private_messages_path

      expect(response).to redirect_to(root_path)
    end

    it "renders the inbox for a signed-in user" do
      login_as(admin_user, scope: :user)

      get private_messages_path

      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /private_messages/new" do
    let(:recipient) { create(:user, role: "contributor") }

    it "renders the compose page for a signed-in user" do
      login_as(admin_user, scope: :user)

      get new_private_message_path, params: { user_id: [recipient.id] }

      expect(response).to have_http_status(:success)
    end
  end
end
