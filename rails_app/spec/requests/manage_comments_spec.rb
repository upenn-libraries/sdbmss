require "rails_helper"

RSpec.describe "Manage comments", type: :request do
  let(:admin_user) { create(:admin) }
  let(:regular_user) { create(:user) }
  let(:source) { create(:edit_test_source, created_by: admin_user) }
  let(:entry) { create(:edit_test_entry, source: source, created_by: admin_user, approved: true) }

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

  describe "POST /comments" do
    it "redirects signed-in admin to the commentable anchor" do
      login_as(admin_user, scope: :user)

      post comments_path, params: {
        commentable_id: entry.id,
        commentable_type: "Entry",
        comment: "Coverage comment"
      }

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(entry_path(entry, anchor: "comment_#{Comment.last.id}"))
    end
  end

  describe "GET /comments/:id" do
    it "redirects to commentable anchor when commentable still exists" do
      comment = Comment.create!(comment: "Anchor me", commentable: entry, created_by: admin_user)

      get comment_path(comment)

      expect(response).to redirect_to(entry_path(entry, anchor: "comment_#{comment.id}"))
    end
  end

  describe "DELETE /comments/:id.json" do
    it "marks comment as deleted for signed-in admin" do
      comment = Comment.create!(comment: "Deletable", commentable: entry, created_by: admin_user)
      login_as(admin_user, scope: :user)

      delete comment_path(comment, format: :json)

      expect(response).to have_http_status(:ok)
      expect(comment.reload.deleted).to be(true)
    end

    it "returns ok and does not delete for regular user" do
      comment = Comment.create!(comment: "Protected", commentable: entry, created_by: admin_user)
      login_as(regular_user, scope: :user)

      delete comment_path(comment, format: :json)

      expect(response).to have_http_status(:ok)
      expect(comment.reload.deleted).to be(false)
    end
  end
end
