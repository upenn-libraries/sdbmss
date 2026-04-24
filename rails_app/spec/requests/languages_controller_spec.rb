require "rails_helper"

RSpec.describe "LanguagesController", type: :request do
  let(:admin)  { create(:admin) }
  let(:source) { Language.create!(name: "ZzzMergeSource#{rand(9999)}", created_by: admin) }
  let(:target) { Language.create!(name: "ZzzMergeTarget#{rand(9999)}", created_by: admin) }

  before do
    allow(SDBMSS::IndexJob).to receive(:perform_later)
    login_as(admin, scope: :user)
  end

  # ---------------------------------------------------------------------------
  # POST /languages/:id/merge (with confirm)
  # ---------------------------------------------------------------------------
  describe "POST /languages/:id/merge" do
    before do
      # stub Solr MLT used in non-confirm path
      allow_any_instance_of(LanguagesController).to receive(:mlt_search).and_return(double(results: []))
    end

    context "with confirm param" do
      it "merges source into target and redirects" do
        post merge_language_path(source),
             params: { target_id: target.id, confirm: "yes" }

        expect(response).to redirect_to(language_path(target))
        expect(Language.exists?(source.id)).to be false
      end
    end

    context "without confirm param (select stage)" do
      it "renders without merging" do
        get merge_language_path(source), params: { target_id: target.id }
        expect(response).to have_http_status(:ok)
        expect(Language.exists?(source.id)).to be true
      end
    end
  end
end
