require "rails_helper"

RSpec.describe "Manage Names", type: :request do
  let(:admin_user) { create(:admin) }
  let(:review_target) { Name.find_or_create_agent("Coverage Target Name") }

  describe "GET /names" do
    it "renders the manage names page for a signed-in user" do
      login_as(admin_user, scope: :user)
      get names_path

      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /names/:id/merge" do
    it "renders the merge page for an admin user" do
      author = Name.author
      author.update!(name: "Joe Zchmoe")
      author.index!

      login_as(admin_user, scope: :user)
      get merge_name_path(author.id)

      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /names/:id/merge" do
    it "renders the merge page for admin when confirm is no" do
      source_name = Name.find_or_create_agent("Coverage Merge Source")
      source_name.update!(is_author: true)
      SolrTools.index_records!(source_name)

      login_as(admin_user, scope: :user)
      post merge_name_path(source_name.id), params: {
        target_id: source_name.id,
        confirm: "no"
      }

      expect(response).to have_http_status(:success)
    end

    it "merges source into target when confirm is yes" do
      source_name = Name.find_or_create_agent("Coverage Merge Source 2")
      target_name = Name.find_or_create_agent("Coverage Merge Target 2")
      source_name.update!(is_author: true)
      target_name.update!(is_author: true)
      SolrTools.index_records!(source_name, target_name)

      login_as(admin_user, scope: :user)

      post merge_name_path(source_name.id), params: {
        target_id: target_name.id,
        confirm: "yes",
        name: target_name.name,
        is_author: true,
        is_artist: target_name.is_artist,
        is_scribe: target_name.is_scribe,
        is_provenance_agent: target_name.is_provenance_agent,
        viaf_id: target_name.viaf_id,
        other_info: target_name.other_info
      }

      expect(response).to redirect_to(name_path(target_name))
      expect(source_name.reload.deleted).to be(true)
    end
  end

  describe "GET /names/problems" do
    it "renders problems page with defaults" do
      login_as(admin_user, scope: :user)

      get problems_names_path

      expect(response).to have_http_status(:success)
    end

    it "renders problems page with explicit filters" do
      login_as(admin_user, scope: :user)

      get problems_names_path, params: { type: "id", letter: "A", page: 0 }

      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /names/:id/timeline.json" do
    it "returns json timeline payload" do
      login_as(admin_user, scope: :user)

      get timeline_name_path(review_target, format: :json)

      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("application/json")
    end
  end

  describe "GET /names/suggest.json" do
    it "returns json array for signed-in admin" do
      login_as(admin_user, scope: :user)

      get suggest_names_path(format: :json), params: { name: "Augustine", check_exists: true }

      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("application/json")
      json = JSON.parse(response.body)
      expect(json).to include("already_exists", "results")
      expect(json["results"]).to be_a(Array)
    end
  end

  describe "PATCH /names/:id/revert_confirm" do
    it "renders revert confirmation with error when no versions selected" do
      login_as(admin_user, scope: :user)

      patch revert_confirm_name_path(review_target)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("This reversion will not result in any change in information")
    end
  end

  describe "PATCH /names/:id/revert" do
    it "raises record-not-found when version_id is missing (current behavior)" do
      login_as(admin_user, scope: :user)

      expect { patch revert_name_path(review_target) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
