require "rails_helper"

RSpec.describe "EntryManuscriptsController#update_multiple", type: :request do
  let(:admin)      { create(:admin) }
  let(:source)     { Source.create!(source_type: SourceType.auction_catalog, created_by: admin) }
  let(:entry)      { Entry.create!(source: source, created_by: admin) }
  let(:manuscript) { Manuscript.create!(created_by: admin) }
  let!(:em) do
    EntryManuscript.create!(
      entry: entry, manuscript: manuscript,
      relation_type: "is", created_by: admin, updated_by: admin
    )
  end

  before { login_as(admin, scope: :user) }

  def put_update_multiple(entry_manuscripts:, cumulative_updated_at: manuscript.cumulative_updated_at)
    put update_multiple_entry_manuscripts_path,
        params: {
          manuscript_id:        manuscript.id,
          cumulative_updated_at: cumulative_updated_at,
          entry_manuscripts:    entry_manuscripts
        },
        as: :json
  end

  describe "PUT /entry_manuscripts/update_multiple" do
    context "when cumulative_updated_at matches (no concurrent edit)" do
      it "updates relation_type on an existing entry_manuscript" do
        put_update_multiple(entry_manuscripts: [
          { id: em.id, entry_id: entry.id, manuscript_id: manuscript.id, relation_type: "possible" }
        ])

        expect(response).to have_http_status(:ok)
        expect(em.reload.relation_type).to eq("possible")
      end

      it "destroys an entry_manuscript when _destroy is set" do
        put_update_multiple(entry_manuscripts: [
          { id: em.id, entry_id: entry.id, manuscript_id: manuscript.id, _destroy: true }
        ])

        expect(response).to have_http_status(:ok)
        expect(EntryManuscript.where(id: em.id)).to be_empty
      end
    end

    context "when cumulative_updated_at does not match (concurrent edit conflict)" do
      it "returns 422 with a conflict error message" do
        put_update_multiple(
          cumulative_updated_at: "1970-01-01 00:00:00",
          entry_manuscripts: [
            { id: em.id, entry_id: entry.id, manuscript_id: manuscript.id, relation_type: "possible" }
          ]
        )

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json.dig("errors", "base")).to include("Another change was made")
        # entry_manuscript should not have been modified
        expect(em.reload.relation_type).to eq("is")
      end
    end
  end
end
