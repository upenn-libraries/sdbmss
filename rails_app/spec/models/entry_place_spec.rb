require 'rails_helper'

RSpec.describe EntryPlace, type: :model do
  it_behaves_like "a TellBunny-enabled model"

  describe "#display_value" do
    it "returns place name and observed name" do
      place = create(:place, name: "Italy")
      entry_place = build(:entry_place, place: place, observed_name: "Italia")
      expect(entry_place.display_value).to include("Italy")
      expect(entry_place.display_value).to include("(Italia)")
    end
  end
end
