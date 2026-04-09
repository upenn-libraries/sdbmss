require "rails_helper"

RSpec.describe "Community", type: :request do
  describe "GET /community" do
    it "renders the community page" do
      get community_path

      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /community/stats" do
    let!(:activity_user) { create(:user, role: "contributor") }
    let!(:recent_activity) { Activity.create!(event: "update", user: activity_user, item: activity_user) }
    let!(:recent_entry) { create(:edit_entry_with_titles, created_by: activity_user) }

    it "returns json stats for the requested period" do
      get "/community/stats.json", params: { measure: "week", quantity: 6 }

      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("application/json")

      json = JSON.parse(response.body)
      expect(json).to include("result", "entries", "activity")
    end
  end
end
