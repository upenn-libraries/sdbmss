require "rails_helper"

RSpec.describe "Manage Names", type: :request do
  let(:admin_user) { User.where(role: "admin").first || create(:admin) }

  describe "GET /names" do
    it "renders the manage names page for a signed-in user" do
      login_as(admin_user, scope: :user)
      get names_path

      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /names/:id/merge" do
    it "renders the merge page for an admin user" do
      author = Name.author
      author.update!(name: "Joe Zchmoe")

      login_as(admin_user, scope: :user)
      get merge_name_path(author.id)

      expect(response).to have_http_status(:success)
    end
  end
end
