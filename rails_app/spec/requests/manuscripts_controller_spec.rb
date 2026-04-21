require "rails_helper"

RSpec.describe "ManuscriptsController", type: :request do
  let(:admin_user) { create(:admin) }
  let(:manuscript) { create(:manuscript, name: "MS 123", created_by: admin_user) }

  before do
    login_as(admin_user, scope: :user)
  end

  describe "GET /manuscripts" do
    it "renders the index page" do
      get manuscripts_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /manuscripts/:id" do
    it "renders the show page" do
      get manuscript_path(manuscript)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(manuscript.public_id)
    end
  end

  describe "GET /manuscripts/:id/table" do
    it "renders the table view" do
      get table_manuscript_path(manuscript)
      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("text/html")
    end
  end

  describe "GET /manuscripts/:id/citation" do
    it "renders the citation page" do
      get citation_manuscript_path(manuscript)
      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("text/html")
    end

    it "renders without layout for XHR" do
      get citation_manuscript_path(manuscript), xhr: true
      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("text/html")
    end
  end
end
