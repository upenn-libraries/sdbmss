
require 'json'
require "rails_helper"
require 'net/http'

# There's JS on most of these pages. Not all features use JS, but
# there's no good reason NOT to use the js driver, so we do.
describe "Blacklight Search", :js => true do

  before :all do
    # since we already have a set of reference data, we use that here
    # instead of creating another set of test data. The consequence is
    # that these tests don't exercise everything as thoroughly as they
    # should, but they're probably good enough.

    SDBMSS::ReferenceData.create_all

    SDBMSS::Util.wait_for_solr_to_be_current

    @user = User.create!(
      email: 'search@search.com',
      username: 'search',
      password: 'somethingunguessable',
    )
  end

  # Returns a record from Hill catalog
  def get_hill_entry_by_cat_num cat_num
    Entry
      .joins(:source => [:source_agents => :agent])
      .where(:names => { :name => "Jonathan A. Hill" },
             :catalog_or_lot_number => cat_num)
      .first
  end

  it "should load main landing page" do
    visit root_path
    expect(page).to have_selector("input#q")
  end

  it "should display all entries" do
    visit root_path
    click_button('search')
    expect(page).to have_selector("#documents")

    Entry.all.order(id: :desc).limit(5).each do |entry|
      expect(page).to have_link(entry.public_id)
    end

    expect(page).to have_selector(".export-csv")
  end

  it "should display results for an Author facet" do
    visit root_path
    click_button('search')
    expect(page).to have_selector("#documents")

    first(:css, "#facet-author .facet_select").click
    expect(page).to have_selector("#documents")
  end

  it "should display list of Author facet values" do
    visit root_path
    click_button('search')
    expect(page).to have_selector("#documents")

    first(:css, ".more_facets_link a").click

    expect(page).to have_content "Browsing facet: Author"

    first(:css, ".az").click

    expect(page).to have_content "Browsing facet: Author"
    expect(page).to have_content "Prefix"

    click_link("D")

    expect(page).to have_content "Browsing facet: Author"
    expect(page).not_to have_content "Augustine"
    expect(page).to have_content "Dokeianos"
  end

  # this test disabled because we removed the search field dropdown
  # it "should search on Provenance" do
  #   visit root_path
  #   select "Provenance", from: "search_field"
  #   fill_in "q", with: "Tomkinson"
  #   click_button('search')

  #   entry_one = get_hill_entry_by_cat_num(1)
  #   entry_nine = get_hill_entry_by_cat_num(9)

  #   expect(page).to have_link(entry_one.public_id)
  #   expect(page).not_to have_link(entry_nine.public_id)
  # end

  it "should load advanced search page" do
    visit advanced_search_path

    # all text search fields should show up in dropdown
    expect(find_by_id('text_field_0').all("option").length).to eq(27)
    # all numeric search fields should show up in dropdown
    expect(find_by_id('numeric_field_0').all("option").length).to eq(14)
  end

  it "should do advanced search using numeric range on Height" do
    visit advanced_search_path

    fill_in "numeric_start_0", with: 250
    fill_in "numeric_end_0", with: 260
    select "Height", from: "numeric_field_0"

    find_by_id('advanced-search-submit').click

    entry_one = get_hill_entry_by_cat_num(1)
    entry_nine = get_hill_entry_by_cat_num(9)

    expect(page).to have_link(entry_one.public_id)
    expect(page).not_to have_link(entry_nine.public_id)
  end

  it "should load show Entry page" do
    entry = Entry.last
    visit entry_path(entry)
    expect(page).to have_xpath("//h1[contains(.,'#{entry.public_id}')]")
  end

  # poltergeist's implementation of page.source wraps the JSON
  # response in HTML for display, so we set js: false for this test.
  it "should load show Entry page (json format)", js: false do
    entry = Entry.last
    visit entry_path(entry, format: :json)
    data = JSON.parse(page.source)
    expect(data["id"]).to eq(entry.id)
  end

  it "should 404 on show Entry page for deleted entry" do
    entry = Entry.new(
      source: Source.last,
      deleted: true
    )
    entry.save!

    sleep(0.5)

    visit entry_path(entry)
    expect(page.status_code).to eq(404)
  end

  it "should load show Source page" do
    source = Source.last
    visit source_path(source)
    expect(page).to have_xpath("//h1[contains(.,'#{source.public_id}')]")
  end

  it "should load show Agent page" do
    agent = Name.where(is_provenance_agent: true).last
    visit agent_path(agent)
    expect(page).to have_xpath("//h1[contains(.,'#{agent.public_id}')]")
  end

  it "should load show Name page" do
    name = Name.last
    visit name_path(name)
    expect(page).to have_xpath("//h1[contains(.,'#{name.public_id}')]")
  end

  it "should load show Profile page" do
    user = User.last
    visit profile_path(user.username)
    expect(page).to have_content(user.username)
  end

  it "should load show Manuscript page" do
    # randomly link 2 entries together in a MS
    entries = Entry.last(2)
    ms = Manuscript.create!(
      entry_manuscripts_attributes: [
        { entry_id: entries[0].id, relation_type: EntryManuscript::TYPE_RELATION_IS },
        { entry_id: entries[1].id, relation_type: EntryManuscript::TYPE_RELATION_IS },
      ]
    )

    visit manuscript_path(ms)

    expect(page).to have_content(ms.public_id)
  end

  it "should bookmark an Entry and remove it" do
    visit new_user_session_path
    fill_in 'user_login', :with => @user.username
    fill_in 'user_password', :with => 'somethingunguessable'
    click_button 'Log in'
    expect(page).to have_content 'Signed in successfully'

    visit root_path
    fill_in "q", with: "Tomkinson"
    click_button('search')
    expect(page).to have_selector("#documents")

    entry_one = get_hill_entry_by_cat_num 1
    find_by_id("bookmark_toggle_" + entry_one.id.to_s).click

    # page does ajax call; wait for toggle to be checked
    expect(page).to have_selector("#bookmark_toggle_" + entry_one.id.to_s + "[value='Remove Bookmark']")

    visit bookmarks_path
    expect(page).to have_link(entry_one.public_id)
    find_by_id("bookmark_toggle_" + entry_one.id.to_s).click

    # page does ajax call; wait for toggle to be checked
    expect(page).not_to have_selector("#bookmark_toggle_" + entry_one.id.to_s + "[value='Remove Bookmark']")

    visit bookmarks_path
    expect(page).not_to have_link(entry_one.public_id)
  end

  # poltergeist has trouble loading the csv, so we don't use it
  it "should export bookmarks as CSV", :js => false do
    entry = Entry.first

    Bookmark.create!(
      user_id: @user.id,
      user_type: 'User',
      document_id: entry.id,
      document_type: "SolrDocument"
    )

    visit new_user_session_path
    fill_in 'user_login', :with => @user.username
    fill_in 'user_password', :with => 'somethingunguessable'
    click_button 'Log in'
    expect(page).to have_content 'Signed in successfully'

    visit bookmarks_path
    expect(page).to have_link(entry.public_id)

    click_link("Download as CSV")

    found = false
    CSV.parse(page.source, headers: true) do |row|
      found = true if row["id"] == entry.id.to_s
    end
    expect(found).to eq(true)
  end

  it "should add search to History" do
    visit root_path
    fill_in "q", with: "My Unique Search"
    click_button('search')
    expect(page).to have_selector("#documents")

    visit search_history_path

    expect(page).to have_content("My Unique Search")
  end

end
