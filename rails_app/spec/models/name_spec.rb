
require "rails_helper"

describe Name do

  describe "methods" do

    it "should get suggestions", :flaky do
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

    it "should merge records" do
      author1 = Name.author
      author1.name = "Some Author 1"
      author1.save!

      author2 = Name.author
      author2.name = "Some Author 2"
      author2.save!

      author1.merge_into(author2)

      expect(author1.deleted).to eq(true)
    end

    it "should update counters appropriately when records are merged" do
      admin = create(:admin)

      author = Name.create!(is_author: true, name: "Merge Counter Author", created_by: admin)
      artist = Name.create!(is_artist: true, name: "Merge Counter Artist", created_by: admin)

      source = Source.create!(source_type: SourceType.auction_catalog, created_by: admin)
      entry1 = Entry.create!(source: source, created_by: admin, approved: true)
      entry2 = Entry.create!(source: source, created_by: admin, approved: true)

      EntryAuthor.create!(entry: entry1, author: author)
      EntryAuthor.create!(entry: entry1, author: artist)
      EntryArtist.create!(entry: entry2, artist: artist)

      author.reload
      artist.reload

      expect(author.authors_count).to eq(author.author_entries.where(deprecated: false, draft: false).count)
      expect(artist.authors_count).to eq(artist.author_entries.where(deprecated: false, draft: false).count)
      expect(artist.artists_count).to eq(artist.artist_entries.where(deprecated: false, draft: false).count)

      artist.merge_into(author)

      author.reload
      expect(author.authors_count).to eq(author.author_entries.where(deprecated: false, draft: false).count)
      expect(author.artists_count).to eq(author.artist_entries.where(deprecated: false, draft: false).count)
    end

    it "should save an extremely large viaf_id" do
      nm = Name.author
      nm.name = "Roger Zelazny"
      vi = 31897056431875614369418736543213451349875981745987605187436598716430581451435143
      nm.viaf_id = vi
      nm.save!

      expect(Name.last.viaf_id).to eq(vi.to_s)
    end

    it "should update 'flags' for name once it has been used in a new place" do
      artist = Name.artist
      artist.name = "Franz Marc"
      artist.save!

      author = Name.author
      author.name = "Ursula Leguin"
      author.save!

      scribe = Name.scribe
      scribe.name = "A Scribe"
      scribe.save!

      provenance = Name.new
      provenance.is_provenance_agent = true
      provenance.name = "Owner"
      provenance.save!

      expect(Name.last.is_author).to eq(false)

      source = Source.new(source_type: SourceType.auction_catalog)
      source.save!
      entry = Entry.new(source: source)
      entry.save!
      entry.update_attributes(
        entry_authors_attributes: [
          {
            author: artist
          }
        ],
        entry_artists_attributes: [
          {
            artist: provenance
          }
        ],
        entry_scribes_attributes: [
          {
            scribe: author
          }
        ],
        provenance_attributes: [
          {
            provenance_agent: scribe
          }
        ]
      )

      expect(artist.is_author).to eq(true)
      expect(provenance.is_artist).to eq(true)
      expect(author.is_scribe).to eq(true)
      expect(scribe.is_provenance_agent).to eq(true)
    end

  end

end
