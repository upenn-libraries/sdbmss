require "rails_helper"

RSpec.describe "DownloadsController", type: :request do
  let(:admin) { create(:admin) }
  let(:other) { create(:user) }

  before { login_as(admin, scope: :user) }

  # ---------------------------------------------------------------------------
  # GET /downloads
  # ---------------------------------------------------------------------------
  describe "GET /downloads" do
    it "lists current user's downloads" do
      Download.create!(filename: "test.csv", user: admin)
      get downloads_path
      expect(response).to have_http_status(:ok)
    end
  end

  # ---------------------------------------------------------------------------
  # GET /downloads/:id/delete (destroy)
  # ---------------------------------------------------------------------------
  describe "GET /downloads/:id/delete" do
    let!(:download) { Download.create!(filename: "del.csv", user: admin) }

    it "destroys download and redirects" do
      expect { get delete_download_path(download) }.to change(Download, :count).by(-1)
      expect(response).to redirect_to(downloads_path)
    end
  end

  # ---------------------------------------------------------------------------
  # GET /downloads/:id (show)
  # ---------------------------------------------------------------------------
  describe "GET /downloads/:id" do
    context "when download belongs to another user" do
      let!(:download) { Download.create!(filename: "other.csv", user: other) }

      it "redirects to root with error" do
        get download_path(download)
        expect(response).to redirect_to(root_path)
      end
    end

    context "when status is 0 (in progress)" do
      let!(:download) { Download.create!(filename: "prog.csv", user: admin, status: 0) }

      it "renders 'in progress'" do
        get download_path(download)
        expect(response.body).to eq("in progress")
      end
    end

    context "when status >= 1 and no ping param" do
      let!(:download) { Download.create!(filename: "done.zip", user: admin, status: 1) }

      before do
        allow_any_instance_of(DownloadsController).to receive(:send_file) { |c, *|
          c.render plain: "file"
        }
      end

      it "calls send_file and marks download as delivering" do
        expect_any_instance_of(DownloadsController).to receive(:send_file)
        get download_path(download)
        expect(download.reload.status).to eq(2)
      end
    end

    context "when status >= 1 and ping param present" do
      let!(:download) { Download.create!(filename: "ping.zip", user: admin, status: 1) }

      it "renders 'done'" do
        get download_path(download), params: { ping: "1" }
        expect(response.body).to eq("done")
      end
    end
  end
end
