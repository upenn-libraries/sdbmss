
require "rails_helper"

describe "Manage sources", :js => true do

  before :all do
    @user = User.create!(
      email: 'testuser@testlanguage.com',
      username: 'languagetestuser',
      password: 'somethingunguessable'
    )
    @source = Source.create!(
      source_type: SourceType.auction_catalog,
      title: "my test source",
      created_by: @user,
    )
    Source.index
  end

  before :each do
    visit new_user_session_path
    fill_in 'user_login', :with => @user.username
    fill_in 'user_password', :with => 'somethingunguessable'
    click_button 'Log in'
    expect(page).to have_content 'Signed in successfully'
  end

  it "should show list of Sources" do
    visit sources_path
    expect(page).to have_content @source.title
  end

  it "should search for Sources" do
    visit sources_path
    expect(page).to have_content @source.title

    page.fill_in "search_value", :with => "test"
    find('#search_submit').click()
    expect(page).not_to have_selector("#spinner", visible: true)

    expect(page).to have_content @source.title
  end

  it "should perform a search with multiple values for the same field" do
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

  it "should perform a search with multiple values for the same field" do
    visit sources_path

    find('#addSearch').click()

    textInputs = page.all("input[name='search_value']")
    searchOptions = page.all("select[name='search_field']")

    textInputs[0].set "Morgan"
    textInputs[1].set "test"

    #select "any", from: "op"

    find('#search_submit').click()

    expect(page).to have_content @source.title 
  end

  it "should delete a Source" do
    # this is a very rough test!
    skip "contributor user cannot delete sources"
    count = Source.count

    # mock out the confirm dialogue
    page.evaluate_script('window.confirm = function() { return true; }')

    visit sources_path
    first(".delete-link").click
    sleep(1)

    expect(Source.count).to eq(count-1)
  end

  it "should create a new Source" do
    visit new_sources_path

    select "Auction/Dealer Catalog", from: 'source_type'
    #find("#source_type").set("Auction/Dealer Catalog")
    sleep 1
    fill_in "title", with: "Completely unique source"
    click_button "Save"

    sleep 1
    expect(Source.last.title).to eq("Completely unique source")
  end

  it "should edit an existing Source" do
    s = Source.last
    visit edit_source_path(s)

    fill_in "title", with: "Utterly specific title"
    click_button "Save"

    sleep 1
    expect(Source.last.title).to eq("Utterly specific title")
  end

end
