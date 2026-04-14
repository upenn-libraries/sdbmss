require "rails_helper"

RSpec.describe "Manage users", type: :request do
  let(:admin_user) { create(:admin) }

  describe "GET /accounts" do
    it "redirects guests to sign in" do
      get accounts_path

      expect(response).to redirect_to(root_path)
    end

    it "renders the manage users page for an admin" do
      login_as(admin_user, scope: :user)

      get accounts_path

      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /accounts/new" do
    it "renders the new user page for an admin" do
      login_as(admin_user, scope: :user)

      get new_account_path

      expect(response).to have_http_status(:success)
    end
  end

end
