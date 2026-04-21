require 'rails_helper'

RSpec.describe Language, type: :model do
  it_behaves_like "a TellBunny-enabled model"

  describe "validations" do
    it "is valid with a name" do
      language = build(:language)
      expect(language).to be_valid
    end

    it "is invalid without a name" do
      language = build(:language, name: nil)
      expect(language).not_to be_valid
    end

    it "is invalid with a duplicate name" do
      name = "Unique Language #{SecureRandom.hex(4)}"
      create(:language, name: name)
      language = build(:language, name: name)
      expect(language).not_to be_valid
    end
  end

  describe "#search_result_format" do
    it "returns a hash with expected keys" do
      language = create(:language, name: "Ancient Greek")
      format = language.search_result_format
      expect(format[:name]).to eq("Ancient Greek")
      expect(format).to include(:id, :public_id, :entries_count)
    end
  end
end
