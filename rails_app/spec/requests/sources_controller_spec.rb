require "rails_helper"

RSpec.describe "SourcesController", type: :request do
  let(:admin_user) { create(:admin) }
  let(:source_type) { SourceType.find_by(name: SourceType::AUCTION_CATALOG) || create(:source_type, name: SourceType::AUCTION_CATALOG) }

  before do
    login_as(admin_user, scope: :user)
  end

  describe "GET /sources" do
    it "renders the index page" do
      get sources_path
      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("text/html")
    end
  end

  describe "POST /sources" do
    let(:source_params) {
      {
        source_type_id: source_type.id,
        title: "New Auction Source",
        date: "20230101",
        source_agents_attributes: [
          { agent_id: create(:name).id, role: SourceAgent::ROLE_SELLING_AGENT }
        ]
      }
    }

    it "creates a new source" do
      expect {
        post sources_path(format: :json), params: source_params
      }.to change(Source, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("application/json")
      expect(Source.last.title).to eq("New Auction Source")
    end
  end

  describe "PUT /sources/:id" do
    let(:source) { create(:edit_test_source, created_by: admin_user) }

    it "updates the source" do
      put source_path(source, format: :json), params: {
        title: "Updated Title"
      }
      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("application/json")
      expect(source.reload.title).to eq("Updated Title")
    end
  end

  describe "DELETE /sources/:id" do
    let!(:source) { create(:edit_test_source, created_by: admin_user) }

    it "marks the source as deleted if it has no entries" do
      expect {
        delete source_path(source, format: :json)
      }.not_to change { Source.unscoped.count }

      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("application/json")
      expect(source.reload.deleted).to be true
    end

    it "returns 422 if it has entries" do
      create(:edit_test_entry, source: source, created_by: admin_user)
      delete source_path(source, format: :json)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(source.reload.deleted).to be false
    end
  end

  describe "POST /sources/:id/merge" do
    let(:source1) { create(:edit_test_source, created_by: admin_user) }
    let(:source2) { create(:edit_test_source, created_by: admin_user) }

    it "merges source1 into source2" do
      # Index them so MLT search doesn't fail
      SolrTools.index_records!(source1, source2)

      # Simulate the merge post
      post merge_source_path(source1), params: {
        target_id: source2.id,
        confirm: "yes",
        title: source2.title
      }
      
      expect(response).to redirect_to(source_path(source2))
      expect(source1.reload.deleted).to be true
    end
  end
end
