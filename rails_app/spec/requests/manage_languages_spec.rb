require "rails_helper"

RSpec.describe "Manage languages", type: :request do
  let(:admin_user) { create(:admin) }

  describe "GET /languages" do
    it "redirects guests to sign in" do
      get languages_path

      expect(response).to redirect_to(root_path)
    end

    it "renders the manage languages page for a signed-in user" do
      login_as(admin_user, scope: :user)

      get languages_path

      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /languages/search.json" do
    before do
      Language.create!(name: "Something new", created_by: admin_user)
      Language.create!(name: "Something old", created_by: admin_user)
      Language.create!(name: "Something else", created_by: admin_user)
      Language.create!(name: "Something zzz", created_by: admin_user)
      Language.reindex
      Sunspot.commit
      login_as(admin_user, scope: :user)
    end

    it "returns json results for a broad query" do
      get search_languages_path(name: "something", format: "json")

      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("application/json")

      json = JSON.parse(response.body)
      expect(json["total"]).to eq(4)
    end

    it "returns json results for a narrow query" do
      get search_languages_path(name: "Something old", format: "json")

      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("application/json")

      json = JSON.parse(response.body)
      expect(json["total"]).to eq(1)
    end
  end
end
