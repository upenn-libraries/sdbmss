require "rails_helper"

RSpec.describe "Manage entry manuscripts", type: :request do
  let(:admin_user) { create(:admin) }
  let(:manuscript) { create(:manuscript, created_by: admin_user, updated_by: admin_user) }
  let(:entry_link) { create(:entry_manuscript, manuscript: manuscript, created_by: admin_user, updated_by: admin_user) }

  describe "GET /entry_manuscripts" do
    it "redirects guests to sign in" do
      get entry_manuscripts_path

      expect(response).to have_http_status(:found)
    end

    it "renders index for signed-in admin" do
      login_as(admin_user, scope: :user)

      get entry_manuscripts_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Manage Links")
    end
  end

  describe "GET /entry_manuscripts/:id" do
    it "redirects to manuscript page for the relation" do
      get entry_manuscript_path(entry_link)

      expect(response).to redirect_to(manuscript_path(manuscript))
    end
  end
end
