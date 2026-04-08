require "lib/data_entry_helpers"
include DataEntryHelpers
require "rails_helper"

describe "Manage sources", :js => true do

  before :each do
    @user = User.where(role: "admin").first
    @source = Source.find_or_create_by(title: "my test source") do |s|
      s.source_type = SourceType.auction_catalog
      s.created_by = @user
    end
    Source.index
    Sunspot.commit
  end

  before :each do
      login(@user, 'somethingunguessable')
  end

  it "should show list of Sources" do
    visit sources_path
    expect(page).to have_content @source.title
  end

  it "should search for Sources", :known_failure do
    visit sources_path
    expect(page).to have_content @source.title

    page.fill_in "search_value", :with => "test"
    page.select "Title", from: "search_field"
    find('#search_submit').click()
    expect(page).not_to have_selector("#spinner", visible: true)

    expect(page).to have_content @source.title
  end

  it "should perform a search with multiple values for the same field", :known_failure do
    visit sources_path

    find('#addSearch').click()

    textInputs = page.all("input[name='search_value']")
    searchOptions = page.all("select[name='search_field']")

    textInputs[0].set "Morgan"
    searchOptions[0].set "Title"

    textInputs[1].set "Libreria"
    searchOptions[1].set "Title"

    find('#search_submit').click()
  end

  it "should perform a search with multiple values for the same field", :known_failure do
    visit sources_path

    find('#addSearch').click()

    textInputs = page.all("input[name='search_value']")
    searchOptions = page.all("select[name='search_field']")

    textInputs[0].set "Morgan"
    textInputs[1].set "test"
    searchOptions[0].find("option", text: "Title").select_option
    searchOptions[1].find("option", text: "Title").select_option

    select "Any", from: "search_op"

    find('#search_submit').click()
    expect(page).not_to have_selector("#spinner", visible: true)

    expect(page).to have_content @source.title 
  end

  it "should delete a Source" do
    # this is a very rough test!
    skip "so anything with a confirmation popup is untestable for the time being :("
    count = Source.count

    # mock out the confirm dialogue
    page.evaluate_script('window.confirm = function() { return true; }')

    visit sources_path
    find(".delete-link", match: :first).click
    sleep(1)

    expect(Source.count).to eq(count-1)
  end

  it "should create a new Source", :known_failure do
    visit new_source_path(source_type: SourceType.auction_catalog.id)

    find('#title').set 'Completely unique source'
    fill_in 'source_date', with: '2014-02-03'
    click_button "Save"

    sleep 1
    expect(Source.last.title).to eq("Completely unique source")
  end

  it "should edit an existing Source" do
    s = Source.last
    visit edit_source_path(s)

    find('#title').set 'Utterly specific title'
    click_button "Save"

    sleep 1
    expect(Source.last.title).to eq("Utterly specific title")
  end

end
