require "rails_helper"

RSpec.describe "EntriesController", type: :request do
  let(:admin_user) { create(:admin) }
  let(:source) { create(:edit_test_source, created_by: admin_user) }

  before do
    login_as(admin_user, scope: :user)
  end

  describe "GET /entries" do
    it "renders the index page" do
      get entries_path
      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("text/html")
    end

    it "returns JSON search results" do
      create(:edit_test_entry, source: source)
      get entries_path(format: :json)
      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("application/json")
      json = JSON.parse(response.body)
      expect(json).to have_key("results")
      expect(json["total"]).to be >= 1
    end
  end

  describe "POST /entries" do
    let(:entry_params) {
      {
        source_id: source.id,
        catalog_or_lot_number: "Lot 42",
        transaction_type: "sale",
        entry_titles_attributes: [
          { title: "New Test Title", order: 0 }
        ],
        entry_authors_attributes: [
          { observed_name: "Original Author", order: 0 }
        ]
      }
    }

    it "creates a new entry with nested attributes" do
      expect {
        post entries_path(format: :json), params: entry_params
      }.to change(Entry, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("application/json")
      entry = Entry.last
      expect(entry.catalog_or_lot_number).to eq("Lot 42")
      expect(entry.entry_titles.first.title).to eq("New Test Title")
    end
  end

  describe "PUT /entries/:id" do
    let(:entry) { create(:edit_test_entry, source: source, created_by: admin_user) }

    it "updates the entry" do
      put entry_path(entry, format: :json), params: {
        id: entry.id,
        catalog_or_lot_number: "Updated Lot",
        cumulative_updated_at: entry.cumulative_updated_at
      }
      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("application/json")
      expect(entry.reload.catalog_or_lot_number).to eq("Updated Lot")
    end

    it "returns 422 on optimistic locking conflict" do
      put entry_path(entry, format: :json), params: {
        id: entry.id,
        catalog_or_lot_number: "Conflict",
        cumulative_updated_at: "stale_timestamp"
      }
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]["base"]).to include("Another change was made")
    end
  end

  describe "DELETE /entries/:id" do
    let!(:entry) { create(:edit_test_entry, source: source, created_by: admin_user) }

    it "marks the entry as deleted but does not destroy the record" do
      expect {
        delete entry_path(entry, format: :json)
      }.not_to change { Entry.unscoped.count }

      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("application/json")
      expect(entry.reload.deleted).to be true
    end
  end

  describe "POST /entries/mark_as_approved" do
    let!(:entry) { create(:edit_test_entry, source: source, approved: false) }

    it "approves multiple entries" do
      post mark_as_approved_entries_path(format: :json), params: { ids: [entry.id] }
      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("application/json")
      expect(JSON.parse(response.body)).to eq({})
      expect(entry.reload.approved).to be true
    end
  end

  describe "POST /entries/:id/deprecate" do
    let!(:entry) { create(:edit_test_entry, source: source, deprecated: false) }

    it "deprecates the entry" do
      post deprecate_entry_path(entry, format: :json)
      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("application/json")
      expect(JSON.parse(response.body)).to eq({})
      expect(entry.reload.deprecated).to be true
    end
  end
end
