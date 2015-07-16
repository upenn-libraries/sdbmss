
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

    # I don't quite trust Rails' counter_cache to behave correctly
    it "should update authors_count appropriately" do
      author = Name.author
      author.name = "Some Author"
      author.save!

      source = Source.new(source_type: SourceType.auction_catalog)
      source.save!
      entry = Entry.new(source: source)
      entry.save!
      entry.update_attributes(
        entry_authors_attributes: [
          {
            author: author
          }
        ]
      )

      author = Name.find(author.id)
      expect(author.authors_count).to eq(1)
    end

  end

end
