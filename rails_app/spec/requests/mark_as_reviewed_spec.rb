require "rails_helper"

RSpec.describe "MarkAsReviewed concern", type: :request do

  let(:admin) { create(:admin) }

  def post_mark_as_reviewed(ids)
    login_as(admin, scope: :user)
    post mark_as_reviewed_languages_path,
        params:  { ids: ids },
        as:      :json
  end

  describe "POST /languages/mark_as_reviewed" do
    let!(:lang1) { Language.create!(name: "ZzzOldFrench#{rand(9999)}", created_by: admin) }
    let!(:lang2) { Language.create!(name: "ZzzOldLatin#{rand(9999)}", created_by: admin) }

    context "when ids are provided" do
      it "marks the specified languages as reviewed" do
        post_mark_as_reviewed([lang1.id, lang2.id])
        expect(response).to have_http_status(:ok)
        expect(lang1.reload.reviewed).to eq(true)
        expect(lang2.reload.reviewed).to eq(true)
      end

      it "records the reviewing user" do
        post_mark_as_reviewed([lang1.id])
        expect(lang1.reload.reviewed_by_id).to eq(admin.id)
      end

      it "returns an empty JSON object" do
        post_mark_as_reviewed([lang1.id])
        expect(JSON.parse(response.body)).to eq({})
      end
    end

    context "when no ids are provided" do
      it "returns ok without updating anything" do
        login_as(admin, scope: :user)
        post mark_as_reviewed_languages_path,
            params:  {},
            as:      :json
        expect(response).to have_http_status(:ok)
      end
    end
  end

end
