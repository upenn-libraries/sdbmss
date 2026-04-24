require "rails_helper"

describe NamePlace do

  let(:user) { create(:user) }
  let(:name) do
    n = Name.author
    n.name = "Test Name"
    n.save!
    n
  end
  let(:place) { Place.create!(name: "Test Place", created_by: user) }

  describe "#display_value" do

    context "when both notbefore and notafter are blank" do
      it "returns just the place name (default mode)" do
        name_place = NamePlace.create!(name: name, place: place, notbefore: nil, notafter: nil)
        expect(name_place.display_value).to eq("Test Place")
      end

      it "returns just the name when mode is 'name'" do
        name_place = NamePlace.create!(name: name, place: place, notbefore: nil, notafter: nil)
        expect(name_place.display_value('name')).to eq("Test Name")
      end
    end

    context "when only notafter is present" do
      it "returns 'place (before YYYY)'" do
        name_place = NamePlace.create!(name: name, place: place, notbefore: nil, notafter: 1500)
        expect(name_place.display_value).to eq("Test Place (before 1500)")
      end
    end

    context "when only notbefore is present" do
      it "returns 'place (after YYYY)'" do
        name_place = NamePlace.create!(name: name, place: place, notbefore: 1200, notafter: nil)
        expect(name_place.display_value).to eq("Test Place (after 1200)")
      end
    end

    context "when both notbefore and notafter are present" do
      it "returns 'place (YYYY to YYYY)'" do
        name_place = NamePlace.create!(name: name, place: place, notbefore: 1200, notafter: 1500)
        expect(name_place.display_value).to eq("Test Place (1200 to 1500)")
      end
    end

  end

  describe "#to_rdf" do
    it "returns a map with model_class, id, and fields" do
      name_place = NamePlace.create!(name: name, place: place, notbefore: 1200, notafter: 1500)
      result = name_place.to_rdf

      expect(result[:model_class]).to eq("name_places")
      expect(result[:id]).to eq(name_place.id)
      expect(result[:fields]).to have_key(:place_id)
      expect(result[:fields]).to have_key(:name_id)
      expect(result[:fields]).to have_key(:notbefore)
      expect(result[:fields]).to have_key(:notafter)
    end

    it "includes URIs for place_id and name_id" do
      name_place = NamePlace.create!(name: name, place: place)
      result = name_place.to_rdf

      expect(result[:fields][:place_id]).to include("https://sdbm.library.upenn.edu/places/")
      expect(result[:fields][:name_id]).to include("https://sdbm.library.upenn.edu/names/")
    end
  end

end
