require "rails_helper"

# CSRF protection is enabled in test env with `protect_from_forgery :null_session`.
# Every mutating request must carry a valid X-CSRF-Token or the session is wiped
# and current_user returns nil.  Pattern: login → GET a page → extract token → mutate.
RSpec.describe "LogActivity concern", type: :request do

  let(:admin) { create(:admin) }

  def csrf_token
    response.body.match(/<meta name="csrf-token" content="([^"]+)"/)[1]
  end

  describe "standard CRUD actions via LanguagesController" do
    describe "POST /languages (create)" do
      it "creates an Activity record with event 'create'" do
        login_as(admin, scope: :user)
        get new_language_path
        token = csrf_token

        expect {
          post languages_path,
               params:  { language: { name: "ZzzNahuatl#{rand(9999)}" } },
               headers: { "X-CSRF-Token" => token }
        }.to change { Activity.where(event: "create", item_type: "Language").count }.by(1)
      end
    end

    describe "PATCH /languages/:id (update)" do
      let!(:lang) { Language.create!(name: "ZzzUpdateLang#{rand(9999)}", created_by: admin) }

      it "creates an Activity record with event 'update'" do
        login_as(admin, scope: :user)
        get edit_language_path(lang)
        token = csrf_token

        expect {
          patch language_path(lang),
                params:  { language: { name: "ZzzUpdatedLang#{rand(9999)}" } },
                headers: { "X-CSRF-Token" => token }
        }.to change { Activity.where(event: "update", item_type: "Language").count }.by(1)
      end
    end

    describe "DELETE /languages/:id (destroy)" do
      let!(:lang) { Language.create!(name: "ZzzDeleteLang#{rand(9999)}", created_by: admin) }

      it "creates an Activity record with event 'destroy'" do
        login_as(admin, scope: :user)
        get edit_language_path(lang)
        token = csrf_token

        expect {
          delete language_path(lang), headers: { "X-CSRF-Token" => token }
        }.to change { Activity.where(event: "destroy", item_type: "Language").count }.by(1)
      end
    end
  end

  # Tests the update_multiple branch (the genuinely uncovered path in log_activity.rb)
  describe "PUT /entry_manuscripts/update_multiple" do
    let(:source)     { Source.create!(source_type: SourceType.auction_catalog, created_by: admin) }
    let(:entry)      { Entry.create!(source: source, created_by: admin) }
    let(:manuscript) { Manuscript.create!(created_by: admin) }

    it "logs Activity for newly created entry_manuscripts" do
      login_as(admin, scope: :user)
      get edit_manuscript_path(manuscript)
      token = csrf_token

      expect {
        put update_multiple_entry_manuscripts_path,
            params: {
              manuscript_id: manuscript.id,
              cumulative_updated_at: manuscript.cumulative_updated_at,
              entry_manuscripts: [
                { entry_id: entry.id, manuscript_id: manuscript.id, relation_type: "is" }
              ]
            },
            headers: { "X-CSRF-Token" => token },
            as: :json
      }.to change { Activity.where(event: "create", item_type: "EntryManuscript").count }.by(1)
    end
  end

end
