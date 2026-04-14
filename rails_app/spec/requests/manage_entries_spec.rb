require "rails_helper"

RSpec.describe "Manage entries", type: :request do
  let(:admin_user) { create(:admin) }

  describe "GET /entries.json" do
    it "returns unauthorized for guests" do
      get entries_path(format: :json)

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns json results for a signed-in admin" do
      login_as(admin_user, scope: :user)

      get entries_path(format: :json)

      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("application/json")

      json = JSON.parse(response.body)
      expect(json["error"]).to be_nil
      expect(json).to include("total", "results")
    end
  end

  describe "GET /entries/:id.json" do
    let(:entry) { Entry.last || create(:entry, source: Source.last || create(:source), created_by: admin_user) }

    it "returns the entry payload" do
      get entry_path(entry, format: :json)

      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("application/json")

      json = JSON.parse(response.body)
      expect(json["id"]).to eq(entry.id)
    end
  end
end
