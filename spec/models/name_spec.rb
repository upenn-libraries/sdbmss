
require "rails_helper"

describe Name do

  describe "methods" do

    it "should get suggestions" do
      suggestions = Name.suggestions("William Shakespeare")
      expect(suggestions[:already_exists]).to eq(false)
      expect(suggestions[:results].length).to be > 0
      expect(suggestions[:results].first[:name]).not_to be_nil
      expect(suggestions[:results].first[:viaf_id]).not_to be_nil
    end

    it "should get_or_create_artist" do
      scribe = Name.scribe
      scribe.name = "Some Scribe"
      scribe.save!

      expect(scribe.is_scribe).to eq(true)

      count = Name.count

      artist = Name.find_or_create_artist("Some Scribe")

      # expect the scribe's role to have changed
      expect(Name.count).to eq(count)
      expect(artist.id).to eq(scribe.id)
      expect(artist.is_artist).to eq(true)
    end

  end

end
