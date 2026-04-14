require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  let(:admin_user) { create(:admin) }

  describe "GET /dashboard/contributions" do
    it "redirects guests to sign in" do
      get dashboard_contributions_path

      expect(response).to redirect_to(root_path)
    end

    it "renders the contributions page for a signed-in user" do
      login_as(admin_user, scope: :user)

      get dashboard_contributions_path

      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /dashboard/activity" do
    it "renders the activity page for a signed-in user" do
      login_as(admin_user, scope: :user)

      get dashboard_activity_path

      expect(response).to have_http_status(:success)
    end
  end
end
