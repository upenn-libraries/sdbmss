
require 'json'
require "rails_helper"

describe "Browse Dericci Records", :js => true do

  before :all do
    @user = User.where(role: "admin").first
    @user2 = User.where(role: "contributor").first

    @d = DericciRecord.create(name: "Camille Desmoulins", place: "Paris", dates: "1794", senate_house: "[Senate House MS901/3/11]")
    DericciRecord.create(name: "Georges Danton", place: "Marseilles", dates: "1795", senate_house: "[Senate House MS901/3/11]")
    DericciRecord.create(name: "Maximilien Robespierre", place: "Toulons", dates: "1796", senate_house: "[Senate House MS901/3/11]")
    DericciRecord.create(name: "Jean-Paul Marat", place: "Nantes", dates: "1793", senate_house: "[Senate House MS901/3/11]")

    Name.create(name: "Camillo", is_author: true)
    Name.create(name: "George Danton", is_author: true)
  end

  before :each do
      login(@user, 'somethingunguessable')
  end

  after :each do
    page.reset!
  end

  it "should display an empty search of collectors/repositories" do
    visit dericci_records_path

    DericciRecord.first(15).each do |record|
      expect(page).to have_content(record.name)
    end
  end

  it "should display the results for the correct alphabatized letter page" do

    visit dericci_records_path
    click_link "G"

    DericciRecord.where("name like ?", "G%").first(15).each do |record|
      expect(page).to have_content(record.name)
    end

  end

  it "should return results for each kind of search" do
    visit dericci_records_path

    within "#main-container" do
      select 'Name', from: :field
      fill_in :term, with: 'Camille'
      click_button 'Search'
    end
    expect(page).to have_content(@d.name)

    within "#main-container" do
      select 'Place', from: :field
      fill_in :term, with: 'Paris'
      click_button 'Search'
    end
    expect(page).to have_content(@d.name)

    within "#main-container" do
      select 'Date', from: :field
      fill_in :term, with: '1794'
      click_button 'Search'
    end
    expect(page).to have_content(@d.name)
  end

  it "should display a dericci record" do
    visit dericci_records_path
    within ".sdbm-table" do
      first("a").click
    end
    expect(page).to have_content(DericciRecord.first.name)
  end

  it "should allow an admin to add a verified link" do
    visit dericci_record_path(DericciRecord.first)
    expect(page).to have_content("Find Verified Name")
    click_link("verify")
    expect(page).to have_content("Find '#{DericciRecord.first}' in SDBM Name Authority")

    expect(page).to have_content("Camillo")
    first(".selectName").click
    expect(page).to have_content "Save"
    click_link("Save")
    expect(page).not_to have_content("Find Verified Name")
  end

  it "should allow an admin to remove verified link" do
    visit dericci_record_path(DericciRecord.first)
    expect(page).not_to have_content("Find Verified Name")
    visit edit_dericci_record_path(DericciRecord.first)
    fill_in "dericci_record_verified_id", with: nil
    click_button "Update De Ricci Record"
    expect(page).to have_content("Find Verified Name")
  end

end