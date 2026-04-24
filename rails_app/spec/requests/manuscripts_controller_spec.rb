require "rails_helper"

RSpec.describe "ManuscriptsController", type: :request do
  let(:admin)      { create(:admin) }
  let(:manuscript) { Manuscript.create!(created_by: admin) }

  before { login_as(admin, scope: :user) }

  # ---------------------------------------------------------------------------
  # PATCH /manuscripts/:id  (update)
  # ---------------------------------------------------------------------------
  describe "PATCH /manuscripts/:id" do
    context "with valid params" do
      it "updates the manuscript and redirects to the show page" do
        patch manuscript_path(manuscript),
              params: { manuscript: { name: "Zzz Updated Manuscript Name" } }

        expect(response).to redirect_to(manuscript_path(manuscript))
        expect(manuscript.reload.name).to eq("Zzz Updated Manuscript Name")
      end

      it "returns the updated record as JSON" do
        patch manuscript_path(manuscript),
              params: { manuscript: { name: "Zzz Json Manuscript" } },
              as:     :json

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["name"]).to eq("Zzz Json Manuscript")
      end
    end
  end

  # ---------------------------------------------------------------------------
  # DELETE /manuscripts/:id  (destroy)
  # ---------------------------------------------------------------------------
  describe "DELETE /manuscripts/:id" do
    context "when the manuscript has no associated entries (deletable)" do
      let!(:target) { Manuscript.create!(created_by: admin) }

      it "destroys the record and returns 200 with empty JSON" do
        expect { delete manuscript_path(target), as: :json }
          .to change(Manuscript, :count).by(-1)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({})
      end
    end

    context "when the manuscript is not deletable (has entries)" do
      before do
        allow_any_instance_of(Manuscript).to receive(:entries_count).and_return(1)
        allow_any_instance_of(Manuscript).to receive_message_chain(:entries, :count).and_return(1)
      end

      it "returns 422 with an error message" do
        delete manuscript_path(manuscript), as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to be_present
      end
    end
  end

  # ---------------------------------------------------------------------------
  # GET /manuscripts/:id/citation
  # ---------------------------------------------------------------------------
  describe "GET /manuscripts/:id/citation" do
    it "responds with 200" do
      get citation_manuscript_path(manuscript)
      expect(response).to have_http_status(:ok)
    end
  end
end
