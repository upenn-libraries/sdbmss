require "rails_helper"

RSpec.describe "ErrorsController", type: :request do
  # The catch-all route `match "*path", to: "errors#render_404"` handles
  # any unmatched path and delegates to render_404.
  describe "unmatched route" do
    it "returns 404 for HTML" do
      get "/this_path_does_not_exist_at_all"
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for JSON" do
      get "/this_path_does_not_exist_at_all", headers: { "Accept" => "application/json" }
      expect(response).to have_http_status(:not_found)
    end
  end
end
