require "rails_helper"

RSpec.describe "Bookmarks", type: :request do
  let(:admin_user) { User.where(role: "admin").first || create(:admin) }
  let(:entry) { Entry.last || create(:entry, source: Source.last || create(:source)) }

  describe "GET /bookmarks.json" do
    before do
      Bookmark.create!(
        user_id: admin_user.id,
        user_type: "User",
        document_id: entry.id.to_s,
        document_type: "Entry",
        tags: "json-tag"
      )
      login_as(admin_user, scope: :user)
    end

    it "returns bookmark data as json" do
      get bookmarks_path(format: :json)

      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("application/json")

      json = JSON.parse(response.body)
      expect(json).to include("bookmarks", "bookmark_tracker")
    end
  end

  describe "GET /bookmarks/export.csv" do
    before do
      Bookmark.create!(
        user_id: admin_user.id,
        user_type: "User",
        document_id: entry.id.to_s,
        document_type: "Entry",
        tags: "csv-tag"
      )
      login_as(admin_user, scope: :user)
    end

    it "returns csv export data" do
      get export_bookmarks_path(format: :csv)

      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("text/csv")
      expect(response.headers["Content-Disposition"]).to include("bookmarks.csv")
    end
  end
end
