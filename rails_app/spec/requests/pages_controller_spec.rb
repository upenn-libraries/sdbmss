require "rails_helper"

RSpec.describe "PagesController", type: :request do
  let(:admin) { create(:admin) }

  before { login_as(admin, scope: :user) }

  # ---------------------------------------------------------------------------
  # POST /pages/:name/preview
  # ---------------------------------------------------------------------------
  describe "POST /pages/:name/preview" do
    let!(:page) { Page.create!(name: "zzz-test-page", filename: "zzz-test-page.html", category: "docs") }

    context "with content param" do
      it "returns sanitized HTML as JSON" do
        post preview_page_path(page),
             params: { content: "<p>Hello <script>bad</script></p>" },
             as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["result"]).to include("<p>")
        expect(json["result"]).not_to include("<script>")
      end
    end

    context "without content param" do
      it "returns error JSON" do
        post preview_page_path(page), params: {}, as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["error"]).to be_present
      end
    end
  end

  # ---------------------------------------------------------------------------
  # GET /pages/:name (show)
  # ---------------------------------------------------------------------------
  describe "GET /pages/:name" do
    context "when page does not exist" do
      it "returns 404" do
        get "/pages/nonexistent-page-zzz"
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # DELETE /pages/:name (destroy)
  # ---------------------------------------------------------------------------
  describe "DELETE /pages/:name" do
    let!(:page) { Page.create!(name: "zzz-delete-page", filename: "zzz-delete.html", category: "docs") }

    before do
      allow(File).to receive(:delete).and_return(1)
    end

    it "destroys the record and redirects" do
      expect { delete "/pages/#{page.name}" }.to change(Page, :count).by(-1)
      expect(response).to redirect_to(pages_path)
    end
  end
end
