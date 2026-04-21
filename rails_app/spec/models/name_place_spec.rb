require 'rails_helper'

RSpec.describe NamePlace, type: :model do
  it_behaves_like "a TellBunny-enabled model"

  describe "#display_value" do
    let(:name) { create(:name, name: "Petrarch") }
    let(:place) { create(:place, name: "Vaucluse") }
    let(:name_place) { build(:name_place, name: name, place: place, notbefore: "1337", notafter: "1353") }

    it "returns place name by default" do
      expect(name_place.display_value).to eq("Vaucluse (1337 to 1353)")
    end

    it "returns name when mode is 'name'" do
      expect(name_place.display_value('name')).to eq("Petrarch (1337 to 1353)")
    end
  end
end
