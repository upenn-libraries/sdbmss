require "rails_helper"

RSpec.describe "NamesController", type: :request do
  let(:admin) { create(:admin) }
  let(:name)  { Name.create!(name: "ZzzTestAuthor", is_author: true, created_by: admin) }

  before { login_as(admin, scope: :user) }

  # ---------------------------------------------------------------------------
  # PATCH /names/:id  (update)
  # ---------------------------------------------------------------------------
  describe "PATCH /names/:id" do
    context "with valid params" do
      it "updates the name and redirects" do
        patch name_path(name), params: { name: "ZzzUpdatedAuthor" }

        expect(response).to redirect_to(name_path(name))
        expect(name.reload.name).to eq("ZzzUpdatedAuthor")
      end

      it "returns the updated record as JSON" do
        patch name_path(name),
              params: { name: "ZzzJsonAuthor" },
              as:     :json

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["name"]).to eq("ZzzJsonAuthor")
      end
    end
  end

  # ---------------------------------------------------------------------------
  # DELETE /names/:id  (destroy)
  # ---------------------------------------------------------------------------
  describe "DELETE /names/:id" do
    context "when the name has no associated records (deletable)" do
      let!(:target) { Name.create!(name: "ZzzDeleteMe", is_author: true, created_by: admin) }

      it "destroys the record and returns 200 with empty JSON" do
        expect { delete name_path(target), as: :json }
          .to change(Name, :count).by(-1)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({})
      end
    end

    context "when the name is in use (not deletable)" do
      before do
        allow_any_instance_of(Name).to receive(:authors_count).and_return(1)
      end

      it "returns 422 with an error message" do
        delete name_path(name), as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to be_present
      end
    end
  end

  # ---------------------------------------------------------------------------
  # GET /names/suggest.json
  # ---------------------------------------------------------------------------
  describe "GET /names/suggest" do
    before do
      Name.create!(name: "ZzzSuggestAuthor", is_author: true, created_by: admin)
    end

    it "returns JSON with a results key" do
      get suggest_names_path, params: { name: "ZzzSuggest" }, as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to have_key("results")
    end
  end

  # ---------------------------------------------------------------------------
  # POST /names/:id/merge  (with confirm=yes)
  # ---------------------------------------------------------------------------
  describe "POST /names/:id/merge (confirm)" do
    let(:target) { Name.create!(name: "ZzzMergeTarget", is_author: true, created_by: admin) }

    before do
      # get_similar calls a Solr MLT query; stub it so the merge action
      # doesn't need a live search index.
      allow_any_instance_of(NamesController).to receive(:get_similar)
    end

    it "merges the name into the target and redirects to the target show page" do
      post merge_name_path(name),
           params: { target_id: target.id, confirm: "yes", name: target.name }

      expect(response).to redirect_to(name_path(target))
    end
  end
end
