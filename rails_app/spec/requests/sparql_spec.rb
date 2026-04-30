require "rails_helper"

RSpec.describe "Sparql", type: :request do
  describe "GET /sparql-space" do
    let(:user) { create(:user) }

    before { login_as(user, scope: :user) }

    it "returns 200" do
      get "/sparql-space"
      expect(response).to have_http_status(200)
    end
  end
end
