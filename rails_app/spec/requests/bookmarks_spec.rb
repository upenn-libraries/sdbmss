require "rails_helper"

RSpec.describe "Bookmarks", type: :request do
  let(:admin_user) { User.where(role: "admin").first || create(:admin) }

  describe "GET /bookmarks.json" do
    before do
      Bookmark.create!(
        user_id: admin_user.id,
        user_type: "User",
        document_id: Entry.last.id.to_s,
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
end
