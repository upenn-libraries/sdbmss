require "rails_helper"

RSpec.describe "EntriesController", type: :request do
  let(:admin)  { create(:admin) }
  let(:source) { Source.create!(source_type: SourceType.auction_catalog, created_by: admin) }
  let(:entry)  { Entry.create!(source: source, created_by: admin) }

  before do
    allow(Sunspot).to receive(:index)
    allow(Sunspot).to receive(:remove)
    login_as(admin, scope: :user)
  end

  # ---------------------------------------------------------------------------
  # POST /entries/mark_as_approved
  # ---------------------------------------------------------------------------
  describe "POST /entries/mark_as_approved" do
    context "with ids" do
      it "marks the entries as approved" do
        entry # ensure persisted
        post mark_as_approved_entries_path,
             params: { ids: [entry.id] },
             as: :json

        expect(response).to have_http_status(:ok)
        entry.reload
        expect(entry.approved).to eq(true)
        expect(entry.approved_by_id).to eq(admin.id)
        expect(entry.approved_at).to be_present
      end
    end

    context "without ids" do
      it "returns 200 without updating anything" do
        post mark_as_approved_entries_path, params: {}, as: :json
        expect(response).to have_http_status(:ok)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # DELETE /entries/:id
  # ---------------------------------------------------------------------------
  describe "DELETE /entries/:id" do
    context "as JSON" do
      it "soft-deletes the entry and returns 200 with empty body" do
        delete entry_path(entry), as: :json

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({})
        expect(entry.reload.deleted).to eq(true)
      end
    end

    context "as HTML" do
      it "redirects to the contributions dashboard" do
        delete entry_path(entry)

        expect(response).to redirect_to(dashboard_contributions_path)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # POST /entries/:id/deprecate
  # ---------------------------------------------------------------------------
  describe "POST /entries/:id/deprecate" do
    let(:manuscript)  { Manuscript.create!(created_by: admin) }
    let(:other_entry) { Entry.create!(source: source, created_by: admin) }

    context "fresh deprecation without a superceding entry" do
      let!(:em) do
        EntryManuscript.create!(
          entry: entry, manuscript: manuscript,
          relation_type: "is", created_by: admin, updated_by: admin
        )
      end

      it "marks the entry as deprecated and destroys its entry_manuscripts" do
        post deprecate_entry_path(entry), params: {}, as: :json

        expect(response).to have_http_status(:ok)
        expect(entry.reload.deprecated).to eq(true)
        expect(EntryManuscript.where(id: em.id)).to be_empty
      end
    end

    context "fresh deprecation with a superceding entry" do
      let!(:em) do
        EntryManuscript.create!(
          entry: entry, manuscript: manuscript,
          relation_type: "is", created_by: admin, updated_by: admin
        )
      end

      it "transfers the entry_manuscript to the superceding entry" do
        post deprecate_entry_path(entry),
             params: { superceded_by_id: other_entry.id },
             as: :json

        expect(response).to have_http_status(:ok)
        expect(entry.reload.deprecated).to eq(true)
        expect(em.reload.entry_id).to eq(other_entry.id)
      end
    end

    context "when an entry_manuscript would collide with the superceding entry" do
      let!(:em) do
        EntryManuscript.create!(
          entry: entry, manuscript: manuscript,
          relation_type: "is", created_by: admin, updated_by: admin
        )
      end

      before do
        # other_entry already linked to the same manuscript → collision
        EntryManuscript.create!(
          entry: other_entry, manuscript: manuscript,
          relation_type: "is", created_by: admin, updated_by: admin
        )
      end

      it "destroys the colliding entry_manuscript instead of transferring" do
        post deprecate_entry_path(entry),
             params: { superceded_by_id: other_entry.id },
             as: :json

        expect(response).to have_http_status(:ok)
        expect(EntryManuscript.where(id: em.id)).to be_empty
      end
    end

    context "when the entry is already deprecated" do
      before { entry.update!(deprecated: true) }

      it "updates superceded_by_id and returns 200" do
        post deprecate_entry_path(entry),
             params: { superceded_by_id: other_entry.id },
             as: :json

        expect(response).to have_http_status(:ok)
        expect(entry.reload.superceded_by_id).to eq(other_entry.id)
      end
    end

    context "when another entry is already superceded by this one" do
      before do
        Entry.create!(source: source, created_by: admin, superceded_by_id: entry.id)
      end

      it "returns 422 with an error" do
        post deprecate_entry_path(entry), params: {}, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
      end
    end
  end

  # ---------------------------------------------------------------------------
  # GET /entries/types
  # ---------------------------------------------------------------------------
  describe "GET /entries/types" do
    it "returns JSON of type constants" do
      get types_entries_path, as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to have_key("sale_agent_role")
      expect(json).to have_key("transaction_type")
      expect(json).to have_key("currency")
    end
  end

  # ---------------------------------------------------------------------------
  # GET /entries/import
  # ---------------------------------------------------------------------------
  describe "GET /entries/import" do
    it "responds with 200" do
      get import_entries_path
      expect(response).to have_http_status(:ok)
    end
  end

  # ---------------------------------------------------------------------------
  # GET /entries/new
  # ---------------------------------------------------------------------------
  describe "GET /entries/new" do
    it "responds with 200" do
      get new_entry_path
      expect(response).to have_http_status(:ok)
    end
  end

  # ---------------------------------------------------------------------------
  # GET /entries/:id/edit
  # ---------------------------------------------------------------------------
  describe "GET /entries/:id/edit" do
    it "responds with 200" do
      get edit_entry_path(entry)
      expect(response).to have_http_status(:ok)
    end
  end

  # ---------------------------------------------------------------------------
  # GET /entries/:id.json (show_json)
  # ---------------------------------------------------------------------------
  describe "GET /entries/:id.json" do
    it "returns JSON representation of the entry" do
      get "/entries/#{entry.id}.json"
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to match(%r{application/json})
    end
  end

  # ---------------------------------------------------------------------------
  # GET /entries/:id/history
  # ---------------------------------------------------------------------------
  describe "GET /entries/:id/history" do
    it "responds with 200" do
      get history_entry_path(entry)
      expect(response).to have_http_status(:ok)
    end
  end

  # ---------------------------------------------------------------------------
  # GET /entries/:id/verify
  # ---------------------------------------------------------------------------
  describe "GET /entries/:id/verify" do
    it "marks entry as verified and redirects to entry" do
      entry.update_columns(unverified_legacy_record: true)
      get verify_entry_path(entry)
      expect(response).to redirect_to(entry_path(entry))
      expect(entry.reload.unverified_legacy_record).to eq(false)
    end
  end

  # ---------------------------------------------------------------------------
  # POST /entries (create)
  # ---------------------------------------------------------------------------
  describe "POST /entries" do
    it "creates a new entry and returns JSON" do
      expect {
        post entries_path,
             params: { source_id: source.id, draft: false },
             as: :json
      }.to change(Entry, :count).by(1)

      expect(response).to have_http_status(:ok)
    end

    it "redirects to edit page for HTML format" do
      post entries_path, params: { source_id: source.id }
      new_entry = Entry.last
      expect(response).to redirect_to(edit_entry_path(new_entry))
    end
  end

  # ---------------------------------------------------------------------------
  # PATCH /entries/:id (update)
  # ---------------------------------------------------------------------------
  describe "PATCH /entries/:id" do
    it "updates entry and returns JSON" do
      patch entry_path(entry),
            params: { draft: true, cumulative_updated_at: entry.cumulative_updated_at },
            as: :json
      expect(response).to have_http_status(:ok)
    end

    it "returns 422 when cumulative_updated_at is stale" do
      patch entry_path(entry),
            params: { draft: true, cumulative_updated_at: "1970-01-01 00:00:00" },
            as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to be_present
    end
  end
end
