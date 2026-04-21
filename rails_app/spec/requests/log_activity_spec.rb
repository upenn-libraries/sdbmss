require "rails_helper"

RSpec.describe "LogActivity concern", type: :request do

  let(:admin) { create(:admin) }

  describe "standard CRUD actions via LanguagesController" do
    describe "POST /languages (create)" do
      it "creates an Activity record with event 'create'" do
        login_as(admin, scope: :user)

        expect {
          post languages_path, params: { language: { name: "ZzzNahuatl#{rand(9999)}" } }
        }.to change { Activity.where(event: "create", item_type: "Language").count }.by(1)
      end
    end

    describe "PATCH /languages/:id (update)" do
      let!(:lang) { Language.create!(name: "ZzzUpdateLang#{rand(9999)}", created_by: admin) }

      it "creates an Activity record with event 'update'" do
        login_as(admin, scope: :user)

        expect {
          patch language_path(lang), params: { language: { name: "ZzzUpdatedLang#{rand(9999)}" } }
        }.to change { Activity.where(event: "update", item_type: "Language").count }.by(1)
      end
    end

    describe "DELETE /languages/:id (destroy)" do
      let!(:lang) { Language.create!(name: "ZzzDeleteLang#{rand(9999)}", created_by: admin) }

      it "creates an Activity record with event 'destroy'" do
        login_as(admin, scope: :user)

        expect {
          delete language_path(lang)
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

      expect {
        put update_multiple_entry_manuscripts_path,
            params: {
              manuscript_id: manuscript.id,
              cumulative_updated_at: manuscript.cumulative_updated_at,
              entry_manuscripts: [
                { entry_id: entry.id, manuscript_id: manuscript.id, relation_type: "is" }
              ]
            },
            as: :json
      }.to change { Activity.where(event: "create", item_type: "EntryManuscript").count }.by(1)
    end
  end

end
