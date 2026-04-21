require "rails_helper"

RSpec.describe "CatalogController", type: :request do
  let(:admin_user) { create(:admin) }

  describe "GET /catalog/:id" do
    it "returns 404 when entry does not exist" do
      get "/catalog/999999999"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /catalog" do
    it "renders the search results page" do
      get search_catalog_path
      expect(response).to have_http_status(:success)
    end

    it "returns JSON search results" do
      get search_catalog_path(format: :json)
      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("application/json")
    end
  end

  describe "GET /catalog/legacy" do
    let(:legacy_host) { "sdbm.library.upenn.edu" }

    it "redirects legacy SCHOENBERG IDs to the new ID path" do
      entry = create(:edit_test_entry)
      # We need to pass the ID in a way that the controller expects, 
      # and ensure the host matches to avoid the legacy rendering block.
      get "/dla/schoenberg/SCHOENBERG_#{entry.id}", 
          params: { id: "SCHOENBERG_#{entry.id}" },
          headers: { "HOST" => legacy_host }
      
      expect(response).to redirect_to("http://sdbm.library.upenn.edu/entries/#{entry.id}")
      expect(flash[:announce]).to include("SDBM_#{entry.id}")
    end

    it "handles missing legacy IDs with an announcement" do
      get "/dla/schoenberg/SCHOENBERG_999999", 
          params: { id: "SCHOENBERG_999999" },
          headers: { "HOST" => legacy_host }
      
      expect(response).to redirect_to("http://sdbm.library.upenn.edu/entries/999999")
      expect(flash[:announce]).to include("cannot be found")
    end
  end
end
