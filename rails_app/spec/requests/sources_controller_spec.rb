require "rails_helper"

RSpec.describe "SourcesController", type: :request do
  let(:admin)  { create(:admin) }
  let(:source) { Source.create!(source_type: SourceType.auction_catalog, created_by: admin) }

  before do
    allow(Sunspot).to receive(:index)
    allow(Sunspot).to receive(:remove)
    # similar action uses mlt_search (Solr); stub at controller level
    allow_any_instance_of(SourcesController).to receive(:get_similar) do |ctrl|
      ctrl.instance_variable_set(:@similar, [])
    end
    login_as(admin, scope: :user)
  end

  # ---------------------------------------------------------------------------
  # GET /sources/new
  # ---------------------------------------------------------------------------
  describe "GET /sources/new" do
    it "responds with 200" do
      get new_source_path
      expect(response).to have_http_status(:ok)
    end
  end

  # ---------------------------------------------------------------------------
  # GET /sources/:id (show)
  # ---------------------------------------------------------------------------
  describe "GET /sources/:id" do
    it "responds with 200" do
      get source_path(source)
      expect(response).to have_http_status(:ok)
    end
  end

  # ---------------------------------------------------------------------------
  # GET /sources/:id/edit
  # ---------------------------------------------------------------------------
  describe "GET /sources/:id/edit" do
    it "responds with 200 for a normal source" do
      get edit_source_path(source)
      expect(response).to have_http_status(:ok)
    end

    # source_type_id 8 (personal observation) not seeded in test DB; branch
    # is covered by the controller code itself but can't be exercised here.
  end

  # ---------------------------------------------------------------------------
  # GET /sources/types
  # ---------------------------------------------------------------------------
  describe "GET /sources/types" do
    it "returns JSON with source_type data" do
      get types_sources_path, as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to have_key("source_type")
      expect(json).to have_key("medium")
    end
  end

  # ---------------------------------------------------------------------------
  # POST /sources (create)
  # ---------------------------------------------------------------------------
  describe "POST /sources" do
    it "creates a source and returns JSON" do
      expect {
        post sources_path,
             params: { source_type_id: SourceType.auction_catalog.id, title: "Zzz New Sale", whether_mss: "Yes" },
             as: :json
      }.to change(Source, :count).by(1)

      expect(response).to have_http_status(:ok)
    end

    it "sets status to No MSS when whether_mss is No" do
      post sources_path,
           params: { source_type_id: SourceType.auction_catalog.id, title: "Zzz No Mss Sale", whether_mss: Source::TYPE_HAS_MANUSCRIPT_NO },
           as: :json
      expect(response).to have_http_status(:ok)
      expect(Source.last.status).to eq(Source::TYPE_STATUS_NO_MSS)
    end
  end

  # ---------------------------------------------------------------------------
  # PATCH /sources/:id (update)
  # ---------------------------------------------------------------------------
  describe "PATCH /sources/:id" do
    it "updates the source and returns JSON" do
      patch source_path(source),
            params: { title: "Zzz Updated Title" },
            as: :json
      expect(response).to have_http_status(:ok)
      expect(source.reload.title).to eq("Zzz Updated Title")
    end

    it "redirects to source page for HTML format on success" do
      patch source_path(source), params: { title: "Zzz Html Update" }
      expect(response).to redirect_to(source_path(source))
    end
  end

  # ---------------------------------------------------------------------------
  # POST /sources/:id/update_status
  # ---------------------------------------------------------------------------
  describe "POST /sources/:id/update_status" do
    it "updates status to a valid value" do
      post update_status_source_path(source),
           params: { status: Source::TYPE_STATUS_ENTERED },
           as: :json
      expect(source.reload.status).to eq(Source::TYPE_STATUS_ENTERED)
    end

    it "returns 422 for an invalid status" do
      post update_status_source_path(source),
           params: { status: "bogus_status" },
           as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  # ---------------------------------------------------------------------------
  # DELETE /sources/:id (destroy)
  # ---------------------------------------------------------------------------
  describe "DELETE /sources/:id" do
    context "when source has no entries" do
      let!(:empty_source) { Source.create!(source_type: SourceType.auction_catalog, created_by: admin) }

      it "soft-deletes the source and returns 200" do
        delete source_path(empty_source), as: :json
        expect(response).to have_http_status(:ok)
        expect(empty_source.reload.deleted).to eq(true)
      end
    end

    context "when source has entries" do
      before { Entry.create!(source: source, created_by: admin) }

      it "returns 422 with an error message" do
        delete source_path(source), as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["error"]).to be_present
      end
    end
  end

  # ---------------------------------------------------------------------------
  # GET /sources/:id/merge
  # ---------------------------------------------------------------------------
  describe "GET /sources/:id/merge" do
    context "with no target_id" do
      it "renders the merge page" do
        get merge_source_path(source)
        expect(response).to have_http_status(:ok)
      end
    end

    context "with a target_id pointing to the same source" do
      it "renders merge page (self-merge warning branch)" do
        get merge_source_path(source), params: { target_id: source.id }
        expect(response).to have_http_status(:ok)
        expect(response.body).to match(/itself/)
      end
    end

    context "with a target_id of a different source type" do
      let!(:other_source) do
        Source.create!(source_type: SourceType.collection_catalog, created_by: admin)
      end

      it "renders merge page (type mismatch warning branch)" do
        get merge_source_path(source), params: { target_id: other_source.id }
        expect(response).to have_http_status(:ok)
        expect(response.body).to match(/same type/)
      end
    end
  end
end
