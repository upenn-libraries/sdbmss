require "rails_helper"

# This app has CSRF protection enabled in the test environment with
# `protect_from_forgery with: :null_session`.  Without a valid CSRF token
# the session is wiped, making current_user nil.  The pattern here is:
#   1. login_as(admin)
#   2. GET a page to receive the CSRF token from the <meta> tag
#   3. Pass that token via the X-CSRF-Token header on the mutating request
RSpec.describe "MarkAsReviewed concern", type: :request do

  let(:admin) { create(:admin) }

  def csrf_token
    response.body.match(/<meta name="csrf-token" content="([^"]+)"/)[1]
  end

  def post_mark_as_reviewed(ids)
    login_as(admin, scope: :user)
    get languages_path
    post mark_as_reviewed_languages_path,
        params:  { ids: ids },
        headers: { "X-CSRF-Token" => csrf_token },
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
        get languages_path
        post mark_as_reviewed_languages_path,
            params:  {},
            headers: { "X-CSRF-Token" => csrf_token },
            as:      :json
        expect(response).to have_http_status(:ok)
      end
    end
  end

end
