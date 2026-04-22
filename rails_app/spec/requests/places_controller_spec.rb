require "rails_helper"

RSpec.describe "PlacesController", type: :request do
  let(:admin)  { create(:admin) }
  let(:source) { Place.create!(name: "ZzzMergeSource#{rand(9999)}", created_by: admin) }
  let(:target) { Place.create!(name: "ZzzMergeTarget#{rand(9999)}", created_by: admin) }

  before do
    allow(SDBMSS::IndexJob).to receive(:perform_later)
    login_as(admin, scope: :user)
  end

  # ---------------------------------------------------------------------------
  # GET /places/:id (show)
  # ---------------------------------------------------------------------------
  describe "GET /places/:id" do
    it "responds with 200 and JSON" do
      get place_path(source), as: :json
      expect(response).to have_http_status(:ok)
    end
  end

  # ---------------------------------------------------------------------------
  # POST /places/:id/merge (with confirm)
  # ---------------------------------------------------------------------------
  describe "POST /places/:id/merge" do
    before do
      allow_any_instance_of(PlacesController).to receive(:mlt_search).and_return(double(results: []))
    end

    context "with confirm param" do
      it "merges source into target and redirects" do
        post merge_place_path(source),
             params: { target_id: target.id, confirm: "yes" }

        expect(response).to redirect_to(place_path(target))
        expect(Place.exists?(source.id)).to be false
      end
    end

    context "without confirm (select stage)" do
      it "renders without merging" do
        get merge_place_path(source), params: { target_id: target.id }
        expect(response).to have_http_status(:ok)
        expect(Place.exists?(source.id)).to be true
      end
    end
  end
end
