require "rails_helper"

RSpec.describe "RepliesController", type: :request do
  let(:admin)  { create(:admin) }
  let(:other)  { create(:user) }
  let(:source) { Source.create!(source_type: SourceType.auction_catalog, created_by: admin) }
  let(:entry)  { Entry.create!(source: source, created_by: admin) }
  let(:comment) do
    Comment.create!(
      comment:        "Test comment",
      created_by:     other,
      commentable:    entry
    )
  end

  before { login_as(admin, scope: :user) }

  # ---------------------------------------------------------------------------
  # POST /replies (create)
  # ---------------------------------------------------------------------------
  describe "POST /replies" do
    it "creates reply and redirects to commentable" do
      expect {
        post replies_path,
             params: { comment_id: comment.id, reply: "Great point" }
      }.to change(Reply, :count).by(1)

      expect(response).to redirect_to(entry_path(entry))
    end

    it "notifies comment author when replier is different user" do
      expect {
        post replies_path,
             params: { comment_id: comment.id, reply: "Agreed" }
      }.to change(Notification, :count).by(1)
    end
  end

  # ---------------------------------------------------------------------------
  # GET /replies/:id (show)
  # ---------------------------------------------------------------------------
  describe "GET /replies/:id" do
    let!(:reply) do
      Reply.create!(comment: comment, reply: "A reply", created_by: admin, updated_by: admin)
    end

    it "redirects to commentable" do
      get reply_path(reply)
      expect(response).to redirect_to(entry_path(entry))
    end
  end

  # ---------------------------------------------------------------------------
  # DELETE /replies/:id (destroy)
  # ---------------------------------------------------------------------------
  describe "DELETE /replies/:id" do
    let!(:reply) do
      Reply.create!(comment: comment, reply: "To delete", created_by: admin, updated_by: admin)
    end

    it "soft-deletes reply and redirects" do
      delete reply_path(reply)
      expect(reply.reload.deleted).to eq(true)
      expect(response).to redirect_to(entry_path(entry))
    end
  end

  # ---------------------------------------------------------------------------
  # PATCH /replies/:id (update)
  # ---------------------------------------------------------------------------
  describe "PATCH /replies/:id" do
    let!(:reply) do
      Reply.create!(comment: comment, reply: "Original", created_by: admin, updated_by: admin)
    end

    it "updates reply text and redirects" do
      patch reply_path(reply), params: { reply: "Updated text" }
      expect(reply.reload.reply).to eq("Updated text")
      expect(response).to redirect_to(entry_path(entry))
    end
  end
end
