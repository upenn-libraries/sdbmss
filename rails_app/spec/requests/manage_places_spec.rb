require "rails_helper"

RSpec.describe "Manage places", type: :request do
  let(:admin_user) { User.where(role: "admin").first || create(:admin) }

  describe "GET /places" do
    it "redirects guests to sign in" do
      get places_path

      expect(response).to redirect_to(root_path)
    end

    it "renders the manage places page for a signed-in user" do
      login_as(admin_user, scope: :user)

      get places_path

      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /places/search.json" do
    before do
      Place.create!(name: "Something new", created_by: admin_user)
      Place.create!(name: "Something old", created_by: admin_user)
      Place.create!(name: "Something else", created_by: admin_user)
      Place.create!(name: "Something zzz", created_by: admin_user)
      Place.reindex
      Sunspot.commit
      login_as(admin_user, scope: :user)
    end

    it "returns json results for a broad query" do
      get search_places_path(name: "something", format: "json")

      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("application/json")

      json = JSON.parse(response.body)
      expect(json["total"]).to eq(4)
    end

    it "returns json results for a narrow query" do
      get search_places_path(name: "Something old", format: "json")

      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("application/json")

      json = JSON.parse(response.body)
      expect(json["total"]).to eq(1)
    end
  end
end
