require "rails_helper"

RSpec.describe "DericciSalesController", type: :request do
  describe "GET /dericci_sales" do
    it "responds with 200" do
      create(:dericci_sale)
      get dericci_sales_path
      expect(response).to have_http_status(:ok)
    end
  end
end
