require "rails_helper"

RSpec.describe "Manage comments", type: :request do
  let(:admin_user) { User.where(role: "admin").first || create(:admin) }

  describe "GET /comments" do
    it "redirects guests to root" do
      get comments_path

      expect(response).to redirect_to(root_path)
    end

    it "renders the index for a signed-in admin" do
      login_as(admin_user, scope: :user)

      get comments_path

      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /comments/search.json" do
    it "returns json search results for a signed-in admin" do
      login_as(admin_user, scope: :user)

      get search_comments_path(format: :json), params: { search_field: ["comment"], comment: ["observation"] }

      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("application/json")

      json = JSON.parse(response.body)
      expect(json).to include("total", "results")
    end
  end
end
