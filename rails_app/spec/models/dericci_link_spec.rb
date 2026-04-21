require 'rails_helper'

RSpec.describe DericciLink, type: :model do
  it_behaves_like "a TellBunny-enabled model"

  describe "callbacks" do
    let(:user) { create(:admin) }
    let(:name) { create(:name) }
    let(:record) { create(:dericci_record) }

    it "creates watches after creation" do
      expect {
        create(:dericci_link, name: name, dericci_record: record, created_by: user)
      }.to change(Watch, :count).by(2)
      
      expect(Watch.exists?(watched: name, user: user)).to be true
      expect(Watch.exists?(watched: record, user: user)).to be true
    end
  end
end
