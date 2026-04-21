require "rails_helper"

RSpec.describe "Manage manuscripts", type: :request do
  let(:admin_user) { create(:admin) }
  let(:manuscript) { create(:manuscript, created_by: admin_user, updated_by: admin_user) }
  let!(:entry_link) { create(:entry_manuscript, manuscript: manuscript, created_by: admin_user, updated_by: admin_user) }
  let(:entry) { entry_link.entry }

  describe "GET /manuscripts" do
    it "redirects guests to sign in" do
      get manuscripts_path

      expect(response).to redirect_to(root_path)
    end

    it "renders the manage manuscripts page for a signed-in user" do
      login_as(admin_user, scope: :user)

      get manuscripts_path

      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("text/html")
    end
  end

  describe "GET /manuscripts/:id" do
    it "renders the public manuscript view" do
      get manuscript_path(manuscript)

      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("text/html")
    end
  end

  describe "GET /manuscripts/:id/table" do
    it "renders the manuscript table view" do
      get table_manuscript_path(manuscript)

      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("text/html")
    end
  end

  describe "GET /manuscripts/:id/citation" do
    it "renders citation page" do
      get citation_manuscript_path(manuscript)

      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("text/html")
    end

    it "renders citation partial payload for xhr requests" do
      get citation_manuscript_path(manuscript), headers: { "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest" }

      expect(response).to have_http_status(:success)
      expect(response.body).to include(manuscript.public_id)
    end
  end

  describe "GET /manuscripts/:id/history" do
    it "renders history page for signed-in admin" do
      login_as(admin_user, scope: :user)

      get history_manuscript_path(manuscript)

      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("text/html")
    end
  end

  describe "GET /manuscripts/:id/manage_entries" do
    it "raises unknown action because route points to missing action (current behavior)" do
      login_as(admin_user, scope: :user)

      expect { get manage_entries_manuscript_path(manuscript) }.to raise_error(AbstractController::ActionNotFound)
    end
  end
end
