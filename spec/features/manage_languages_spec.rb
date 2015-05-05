
require "rails_helper"
require "csv"

describe "Manage languages", :js => true do

  before :all do
    @user = User.create!(
      email: 'testuser@testlanguage.com',
      username: 'languagetestuser',
      password: 'somethingunguessable'
    )
    @language = Language.create!(
      name: "Martian",
      created_by: @user,
    )
  end

  before :each do
    visit new_user_session_path
    fill_in 'user_login', :with => @user.username
    fill_in 'user_password', :with => 'somethingunguessable'
    click_button 'Log in'
    expect(page).to have_content 'Signed in successfully'
  end

  it "should show list of Languages" do
    visit languages_path
    expect(page).to have_content @language.name
  end

  # poltergeist has trouble loading JSON, so we don't use it
  it "should do search for Language", js: false do
    Language.create!(name: "Something new")
    Language.create!(name: "Something old")
    Language.create!(name: "Something else")
    Language.create!(name: "Something zzz")

    visit search_languages_path(term: "thing", format: "json")
    response = JSON.parse(page.source)
    expect(response).to be_a(Hash)
    expect(response["results"].length).to eq(4)

    visit search_languages_path(term: "Something old", format: "json")
    response = JSON.parse(page.source)
    expect(response).to be_a(Hash)
    expect(response["results"].length).to eq(1)
  end

  it "should add a new Language" do
    expect(Language.where(name: "Klingon").count).to eq(0)
    visit new_language_path
    fill_in "language_name", with: "Klingon"
    click_button "Create Language"
    expect(Language.where(name: "Klingon").count).to eq(1)
  end

  it "should delete a Language" do
    # this is a very rough test!
    count = Language.count

    # mock out the confirm dialogue
    page.evaluate_script('window.confirm = function() { return true; }')

    visit languages_path
    first(".delete-link").click
    sleep(1)

    expect(Language.count).to eq(count-1)
  end

  # poltergeist has trouble loading the csv, so we don't use it
  it "should export CSV", :js => false do
    Language.create!(name: "Should appear in export")
    visit search_languages_path(format: :csv)
    found = false
    CSV.parse(page.source, headers: true) do |row|
      found = true if row["name"] == "Should appear in export"
    end
    expect(found).to eq(true)
  end

end
