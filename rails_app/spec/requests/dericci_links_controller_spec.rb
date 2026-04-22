require "rails_helper"

RSpec.describe "DericciLinksController", type: :request do
  let(:admin)         { create(:admin) }
  let(:dericci_record) { DericciRecord.first }
  let(:name)          { Name.where(is_author: true).first }

  before { login_as(admin, scope: :user) }

  # ---------------------------------------------------------------------------
  # POST /dericci_links (create)
  # ---------------------------------------------------------------------------
  describe "POST /dericci_links" do
    context "with from_name param" do
      it "creates link and redirects to name" do
        expect {
          post dericci_links_path,
               params: { name_id: name.id, dericci_record_id: dericci_record.id, from_name: "1" }
        }.to change(DericciLink, :count).by(1)

        expect(response).to redirect_to(name_path(name))
      end
    end

    context "without from_name param" do
      it "creates link and redirects to dericci_record" do
        expect {
          post dericci_links_path,
               params: { name_id: name.id, dericci_record_id: dericci_record.id }
        }.to change(DericciLink, :count).by(1)

        expect(response).to redirect_to(dericci_record_path(dericci_record))
      end
    end
  end

  # ---------------------------------------------------------------------------
  # DELETE /dericci_links/delete_many
  # ---------------------------------------------------------------------------
  describe "DELETE /dericci_links/delete_many" do
    let!(:link) do
      DericciLink.create!(name: name, dericci_record: dericci_record, created_by: admin)
    end

    it "destroys specified links and redirects to dericci_record" do
      expect {
        delete delete_many_dericci_links_path,
               params: { ids: [link.id] }
      }.to change(DericciLink, :count).by(-1)

      expect(response).to redirect_to(dericci_record_path(dericci_record))
    end

    it "redirects to name when from_name param present" do
      delete delete_many_dericci_links_path,
             params: { ids: [link.id], from_name: "1" }

      expect(response).to redirect_to(name_path(name))
    end
  end

  # ---------------------------------------------------------------------------
  # PUT /dericci_links/update_many
  # ---------------------------------------------------------------------------
  describe "PUT /dericci_links/update_many" do
    let!(:link) do
      DericciLink.create!(name: name, dericci_record: dericci_record, created_by: admin, approved: false)
    end

    it "updates specified links and redirects to dericci_record" do
      put update_many_dericci_links_path,
          params: { ids: [link.id], approved: true }

      expect(link.reload.approved).to eq(true)
      expect(response).to redirect_to(dericci_record_path(dericci_record))
    end

    context "when no ids match" do
      it "redirects to dericci_records index" do
        put update_many_dericci_links_path, params: { ids: [] }
        expect(response).to redirect_to(dericci_records_path)
      end
    end
  end
end
