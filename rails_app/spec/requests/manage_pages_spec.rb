require "rails_helper"

RSpec.describe "Manage pages", type: :request do
  let(:admin_user) { User.where(role: "admin").first || create(:admin) }

  describe "GET /pages" do
    it "returns forbidden for guests" do
      get pages_path

      expect(response).to have_http_status(:forbidden)
    end

    it "returns forbidden for non-admin users" do
      %w[contributor editor super_editor].each do |role|
        user = create(:user, role: role)
        login_as(user, scope: :user)

        get pages_path

        expect(response).to have_http_status(:forbidden)
      end
    end

    it "renders the pages index for admins" do
      login_as(admin_user, scope: :user)

      get pages_path

      expect(response).to have_http_status(:success)
    end
  end
end
