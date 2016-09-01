
require 'json'
require "rails_helper"

describe "Manage Names", :js => true do

  before :all do
    @user = User.create!(
      email: 'testuser@test.com',
      username: 'adminuser',
      password: 'somethingunguessable',
      role: 'admin'
    )
    SDBMSS::ReferenceData.create_all
  end

  before :each do
    visit new_user_session_path
    fill_in 'user_login', :with => @user.username
    fill_in 'user_password', :with => 'somethingunguessable'
    click_button 'Log in'
    expect(page).to have_content 'Signed in successfully'
  end

  after :each do
    page.reset!
  end

  it "should show merge options when selecting 'merge' from name list" do
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
    first('.merge-link').click

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
    name_count = Name.count

    author = Name.author
    author.name = "John Updike"
    author.save!

    artist = Name.artist
    artist.name = "Updike, John"
    artist.save!

    expect(name_count + 2).to eq(Name.count)

    e1 = Entry.last(2)[0]
    e2 = Entry.last(2)[1]

    e_author = EntryAuthor.create(entry_id: e1.id, author_id: author.id)
    e_artist = EntryArtist.create(entry_id: e2.id, artist_id: artist.id)

    author = Name.last(2)[0]
    artist = Name.last(2)[1]

    expect(author.authors_count).to eq(1)
    expect(artist.artists_count).to eq(1)

    
  end
end