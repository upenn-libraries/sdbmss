require "rails_helper"

RSpec.describe "Manage sources", type: :request do
  let(:admin_user) { create(:admin) }

  describe "GET /sources" do
    it "redirects guests to sign in" do
      get sources_path

      expect(response).to redirect_to(root_path)
    end

    it "renders the manage sources page for a signed-in user" do
      login_as(admin_user, scope: :user)

      get sources_path

      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /sources/search.json" do
    before do
      create(:edit_test_source, created_by: admin_user, title: "A unique source title for request search")
      Source.reindex
      Sunspot.commit
      login_as(admin_user, scope: :user)
    end

    it "returns json results for a title query" do
      get search_sources_path(search_field: "title", search_value: "request search", format: "json")

      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("application/json")

      json = JSON.parse(response.body)
      expect(json).to include("total", "results")
    end
  end
end
