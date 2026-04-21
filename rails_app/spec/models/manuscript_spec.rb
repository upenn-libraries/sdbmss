require 'rails_helper'

RSpec.describe Manuscript, type: :model do
  it_behaves_like "a TellBunny-enabled model"

  describe "#display_value" do
    it "returns the public_id and name" do
      manuscript = create(:manuscript, name: "Test MS")
      expect(manuscript.display_value).to include(manuscript.public_id)
      expect(manuscript.display_value).to include("Test MS")
    end
  end

  describe "#all_provenance_grouped_by_name" do
    let(:manuscript) { create(:manuscript) }
    let(:entry) { create(:edit_test_entry) }
    let!(:em) { create(:entry_manuscript, entry: entry, manuscript: manuscript, relation_type: EntryManuscript::TYPE_RELATION_IS) }
    
    it "groups provenance records from linked entries" do
      entry.provenance.create!(observed_name: "Owner A", order: 0)
      entry.provenance.create!(observed_name: "Owner A", order: 1)
      
      grouped = manuscript.all_provenance_grouped_by_name
      expect(grouped.size).to eq(1)
      expect(grouped.first[0]).to eq("Owner A")
      expect(grouped.first[1].size).to eq(2)
    end
  end
end
