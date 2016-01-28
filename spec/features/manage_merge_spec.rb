
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

    visit names_path
    expect(page).to have_content("Merge")

    #select most recently created author (author2) to MERGE
    first('.merge-link').click

    expect(page).to have_content("Merge")
    expect(page).to have_content(author2.id)

    fill_in "target_id", :with => author.id
    click_button "Show"

    #MERGE TO author (John Milton)
    expect(page).to have_content(author.name)
    click_button "Yes"

    #Success message
    expect(page).to have_content("Successfully merged")

    #author2 should no longer appear in NAME LIST
    visit names_path
    expect(page).to have_no_content(author2.name)
  end

  it "should update counters correctly on merge" do
    visit names_path

    first('.merge-link').click

    fill_in "target_id", :with => Name.first.id
    click_button "Show"

    click_button "Yes"

    expect(Name.first.authors_count).to eq(EntryAuthor.where(author_id: Name.first.id).count)
    expect(Name.first.artists_count).to eq(EntryArtist.where(artist_id: Name.first.id).count)
    expect(Name.first.scribes_count).to eq(EntryScribe.where(scribe_id: Name.first.id).count)
    expect(Name.first.sale_agents_count).to eq(SaleAgent.where(agent_id: Name.first.id).count)
    expect(Name.first.source_agents_count).to eq(SourceAgent.where(agent_id: Name.first.id).count)
    #expect(Name.last.provenance_count).to eq(0)
    #expect(Name.first.provenance_count).to eq(Provenance.where(provenance_agent_id: Name.first.id).count)
  end
end