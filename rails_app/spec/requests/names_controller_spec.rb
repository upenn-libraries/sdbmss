require "rails_helper"

RSpec.describe "NamesController", type: :request do
  let(:admin_user) { create(:admin) }

  before do
    login_as(admin_user, scope: :user)
  end

  describe "GET /names" do
    it "renders the index page" do
      get names_path
      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("text/html")
    end
  end

  describe "POST /names" do
    it "creates a new name" do
      expect {
        post names_path(format: :json), params: { name: "New Authorized Name", is_author: true }
      }.to change(Name, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(response.content_type.to_s).to include("application/json")
      expect(Name.last.name).to eq("New Authorized Name")
    end
  end

  describe "GET /names/suggest.json" do
    it "returns suggestions for a name" do
      create(:name, name: "William Shakespeare")
      get suggest_names_path(format: :json), params: { name: "William" }
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to have_key("results")
    end
  end

  describe "POST /names/:id/merge" do
    let(:name1) { create(:name, name: "Name 1") }
    let(:name2) { create(:name, name: "Name 2") }

    it "merges name1 into name2" do
      # Index them for MLT if needed (though NamesController uses get_similar which might use MLT)
      SolrTools.index_records!(name1, name2)

      post merge_name_path(name1), params: {
        target_id: name2.id,
        confirm: "yes",
        name: name2.name
      }
      
      expect(response).to redirect_to(name_path(name2))
      # In SDBM, merging a name usually marks it as deleted
      expect(name1.reload.deleted).to be true
    end
  end
end
