require "rails_helper"

RSpec.describe "LinkingToolController", type: :request do
  let(:admin)      { create(:admin) }
  let(:source)     { Source.create!(source_type: SourceType.auction_catalog, created_by: admin) }
  let(:entry)      { Entry.create!(source: source, created_by: admin) }
  let(:manuscript) { Manuscript.create!(created_by: admin) }

  before { login_as(admin, scope: :user) }

  # ---------------------------------------------------------------------------
  # GET /linkingtool/entry/:id
  # ---------------------------------------------------------------------------
  describe "GET /linkingtool/entry/:id" do
    context "entry has no manuscript" do
      it "renders the linking tool show page" do
        get linking_tool_by_entry_path(entry)
        expect(response).to have_http_status(:ok)
      end
    end

    context "entry already linked to manuscript" do
      before do
        EntryManuscript.create!(
          entry: entry, manuscript: manuscript,
          relation_type: "is", created_by: admin, updated_by: admin
        )
      end

      it "redirects to by_manuscript" do
        get linking_tool_by_entry_path(entry)
        expect(response).to redirect_to(linking_tool_by_manuscript_path(manuscript))
      end
    end
  end

  # ---------------------------------------------------------------------------
  # GET /linkingtool/manuscript/:id
  # ---------------------------------------------------------------------------
  describe "GET /linkingtool/manuscript/:id" do
    it "renders the linking tool show page" do
      get linking_tool_by_manuscript_path(manuscript)
      expect(response).to have_http_status(:ok)
    end
  end
end
