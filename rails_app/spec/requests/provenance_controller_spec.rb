require "rails_helper"

RSpec.describe "ProvenanceController", type: :request do
  describe "GET /provenance/parse_observed_date" do
    it "parses a date string and returns JSON with start and end" do
      get parse_observed_date_provenance_index_path, params: { date: "1500" }, as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["date"]["string"]).to eq("1500")
      expect(json["date"]).to have_key("date_start")
      expect(json["date"]).to have_key("date_end")
    end

    it "handles an approximate date string" do
      get parse_observed_date_provenance_index_path, params: { date: "circa 1450" }, as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["date"]).to have_key("date_start")
    end
  end
end
