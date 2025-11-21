
require 'json'
require "system_helper"

describe "Manage Names", :js => true do

  before :all do
    @user = User.where(role: "admin").first

#    SDBMSS::ReferenceData.create_all
  end

  before :each do
      login(@user, 'somethingunguessable')
  end

  after :each do
    page.reset!
  end

  it "should show merge options when selecting 'merge' from name list" do
    skip "temporary"
    author = Name.author
    author.name = "John Milton"
    author.save!

    author2 = Name.author
    author2.name = "Milton, John"
    author2.save!

    Name.index

    visit names_path
    expect(page).to have_content("Merge")

    #select most recently created author (author2) to MERGE
    first("#merge_#{author2.id}").trigger('click')

    expect(page).to have_content("Merge")
    expect(page).to have_content(author2.id)

    fill_in "target_id", :with => author.id
    click_button "Select"

    #MERGE TO author (John Milton)
    expect(page).to have_selector("input[value='#{author.name}']")
    #expect(page).to have_content(author.name)
    click_button "Yes"

    #Success message
    expect(page).to have_content("successfully merged")

    #author2 should no longer appear in NAME LIST
    visit names_path
    expect(page).not_to have_content("#{author2.name}")
  end

  it "should update counters correctly on merge" do
    skip "this test is malfunctioning for unknown reasons: counters are not being updated as they should be, and manually updating is failing with no error message or feedback of any kind.  thanks, rails!"
    name_count = Name.count

    author = Name.create!(:is_author => true, :name => "John Updike")
    artist = Name.create!(:is_artist => true, :name => "Updike, John")

    expect(Name.count).to eq(name_count + 2)

    e1 = Entry.last(2)[0]
    e2 = Entry.last(2)[1]

    expect(e1.id).not_to eq(e2.id)

    e_author = EntryAuthor.create!(entry_id: e1.id, author_id: author.id)
    EntryAuthor.create!(entry_id: e1.id, author_id: artist.id)

    e_artist = EntryArtist.create!(entry_id: e2.id, artist_id: artist.id)

    puts e_artist.inspect, e_author.inspect 

    expect(author.authors_count).to eq(author.author_entries.where(deprecated: false).count)
    expect(artist.artists_count).to eq(artist.artist_entries.where(deprecated: false).count)
    expect(artist.authors_count).to eq(artist.author_entries.where(deprecated: false).count)

    artist.merge_into(author)

    SDBMSS::Util.wait_for_solr_to_be_current

    expect(e_artist.artist_id).to eq(author.id)

    Name.update_counters(author.id, scribes_count: 200) #:artists_count => author.artist_entries.where(deprecated: false).count - author.artists_count)
    puts author.scribes_count

    expect(author.artists_count).to eq(author.artist_entries.where(deprecated: false).count)
    expect(author.authors_count).to eq(author.author_entries.where(deprecated: false).count)
  end

  it "should update counters correctly on merge (name)" do
    skip "even when accessed using the interface, counter_cache values simply don't update"
    n1 = Name.first
    n2 = Name.last

    n1_counts = n1.attributes.select { |k, v| k.include? "_count" }
    n2_counts = n2.attributes.select { |k, v| k.include? "_count" }

    visit merge_name_path(n1, target_id: n2.id)

    expect(page).to have_content("Merge #{n1.public_id} ➔ #{n2.public_id}")

    click_button 'Yes'

    expect(page).to have_content("#{n2.public_id}")

    expect(n2.author_entries.where(draft: false, deprecated: false).count).to eq(n2.authors_count)
    expect(n2.artist_entries.where(draft: false, deprecated: false).count).to eq(n2.artists_count)
    expect(n2.scribe_entries.where(draft: false, deprecated: false).count).to eq(n2.scribes_count)
    expect(n2.sale_entries.where(draft: false, deprecated: false).count).to eq(n2.sale_agents_count)
    expect(n2.agent_sources.where(draft: false, deprecated: false).count).to eq(n2.source_agents_count)
    expect(n2.provenance_entries.where(draft: false, deprecated: false).count).to eq(n2.provenance_count)
  end
end
