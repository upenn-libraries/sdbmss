require "rails_helper"

RSpec.describe "DericciNotesController", type: :request do
  describe "GET /dericci_notes" do
    it "responds with 200" do
      create(:dericci_note)
      get dericci_notes_path
      expect(response).to have_http_status(:ok)
    end

    it "paginates via page param" do
      get dericci_notes_path, params: { page: 1 }
      expect(response).to have_http_status(:ok)
    end
  end
end
