require "rails_helper"

RSpec.describe "EntryManuscripts update_multiple", type: :request do
  let(:admin_user) { create(:admin) }

  def update_multiple_payload(manuscript_id:, entry_manuscript:, relation_type:)
    {
      manuscript_id: manuscript_id,
      cumulative_updated_at: Manuscript.find(manuscript_id).cumulative_updated_at,
      entry_manuscripts: [
        {
          id: entry_manuscript.id,
          manuscript_id: manuscript_id,
          entry_id: entry_manuscript.entry_id,
          relation_type: relation_type
        }
      ]
    }
  end

  it "returns 422 with overwrite-conflict error when cumulative_updated_at is stale" do
    manuscript = create(:manuscript, created_by: admin_user, updated_by: admin_user)
    source = create(:edit_test_source, created_by: admin_user)
    entry = create(:edit_test_entry, source: source, created_by: admin_user, approved: true)
    entry_manuscript = create(
      :entry_manuscript,
      manuscript: manuscript,
      entry: entry,
      relation_type: EntryManuscript::TYPE_RELATION_IS,
      created_by: admin_user,
      updated_by: admin_user
    )

    stale_updated_at = manuscript.cumulative_updated_at
    sleep 1
    entry_manuscript.touch

    login_as(admin_user, scope: :user)

    put update_multiple_entry_manuscripts_path(format: :json), params: {
      manuscript_id: manuscript.id,
      cumulative_updated_at: stale_updated_at,
      entry_manuscripts: [
        {
          id: entry_manuscript.id,
          manuscript_id: manuscript.id,
          entry_id: entry.id,
          relation_type: EntryManuscript::TYPE_RELATION_POSSIBLE
        }
      ]
    }.to_json, headers: {
      "CONTENT_TYPE" => "application/json"
    }

    expect(response).to have_http_status(:unprocessable_entity)

    json = JSON.parse(response.body)
    expect(json.dig("errors", "base")).to eq(
      "Another change was made to the record while you were working. Re-load the page and start over."
    )
  end

  it "returns 200 and updates relation when cumulative_updated_at is current" do
    manuscript = create(:manuscript, created_by: admin_user, updated_by: admin_user)
    source = create(:edit_test_source, created_by: admin_user)
    entry = create(:edit_test_entry, source: source, created_by: admin_user, approved: true)
    entry_manuscript = create(
      :entry_manuscript,
      manuscript: manuscript,
      entry: entry,
      relation_type: EntryManuscript::TYPE_RELATION_IS,
      created_by: admin_user,
      updated_by: admin_user
    )

    login_as(admin_user, scope: :user)

    put update_multiple_entry_manuscripts_path(format: :json), params: update_multiple_payload(
      manuscript_id: manuscript.id,
      entry_manuscript: entry_manuscript,
      relation_type: EntryManuscript::TYPE_RELATION_POSSIBLE
    ).to_json, headers: {
      "CONTENT_TYPE" => "application/json"
    }

    expect(response).to have_http_status(:ok)
    expect(entry_manuscript.reload.relation_type).to eq(EntryManuscript::TYPE_RELATION_POSSIBLE)
  end

  it "returns 200 and ignores records whose entry_id no longer exists" do
    manuscript = create(:manuscript, created_by: admin_user, updated_by: admin_user)
    source = create(:edit_test_source, created_by: admin_user)
    entry = create(:edit_test_entry, source: source, created_by: admin_user, approved: true)

    login_as(admin_user, scope: :user)

    payload = {
      manuscript_id: manuscript.id,
      cumulative_updated_at: manuscript.cumulative_updated_at,
      entry_manuscripts: [
        {
          entry_id: entry.id + 1_000_000,
          manuscript_id: manuscript.id,
          relation_type: EntryManuscript::TYPE_RELATION_IS
        }
      ]
    }

    expect do
      put update_multiple_entry_manuscripts_path(format: :json), params: payload.to_json, headers: {
        "CONTENT_TYPE" => "application/json"
      }
    end.not_to change(EntryManuscript, :count)

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to eq({})
  end

  it "returns 200 and deletes existing relation when _destroy is true" do
    manuscript = create(:manuscript, created_by: admin_user, updated_by: admin_user)
    source = create(:edit_test_source, created_by: admin_user)
    entry = create(:edit_test_entry, source: source, created_by: admin_user, approved: true)
    entry_manuscript = create(
      :entry_manuscript,
      manuscript: manuscript,
      entry: entry,
      relation_type: EntryManuscript::TYPE_RELATION_IS,
      created_by: admin_user,
      updated_by: admin_user
    )

    login_as(admin_user, scope: :user)

    payload = {
      manuscript_id: manuscript.id,
      cumulative_updated_at: manuscript.cumulative_updated_at,
      entry_manuscripts: [
        {
          id: entry_manuscript.id,
          entry_id: entry.id,
          manuscript_id: manuscript.id,
          relation_type: EntryManuscript::TYPE_RELATION_IS,
          _destroy: true
        }
      ]
    }

    expect do
      put update_multiple_entry_manuscripts_path(format: :json), params: payload.to_json, headers: {
        "CONTENT_TYPE" => "application/json"
      }
    end.to change(EntryManuscript, :count).by(-1)

    expect(response).to have_http_status(:ok)
  end
end
