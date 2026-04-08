
require 'json'
require "rails_helper"

describe "Browse Dericci Records", :js => true do
  def open_verified_name_modal
    3.times do
      find("#verify", visible: true).trigger("click")
      return if page.has_selector?("#searchNameAuthority", visible: true, wait: 2)
    end

    raise Capybara::ElementNotFound, "Verified-name modal did not open"
  end

  before :each do
    @user = User.where(role: "admin").first
    @user2 = User.where(role: "contributor").first

    @d = DericciRecord.find_or_create_by(name: "Camille Desmoulins") do |r|
      r.place = "Paris"; r.dates = "1794"; r.senate_house = "[Senate House MS901/3/11]"
    end
    # Reset mutable state: sibling tests may have added links/flags or set verified_id.
    @d.update!(verified_id: nil)
    @d.dericci_links.destroy_all
    @d.dericci_record_flags.destroy_all
    DericciRecord.find_or_create_by(name: "Georges Danton") do |r|
      r.place = "Marseilles"; r.dates = "1795"; r.senate_house = "[Senate House MS901/3/11]"
    end
    DericciRecord.find_or_create_by(name: "Maximilien Robespierre") do |r|
      r.place = "Toulons"; r.dates = "1796"; r.senate_house = "[Senate House MS901/3/11]"
    end
    DericciRecord.find_or_create_by(name: "Jean-Paul Marat") do |r|
      r.place = "Nantes"; r.dates = "1793"; r.senate_house = "[Senate House MS901/3/11]"
    end

    Name.find_or_create_by(name: "Camillo") { |n| n.is_author = true }.index
    Name.find_or_create_by(name: "George Danton") { |n| n.is_author = true }.index
    Sunspot.commit
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
      find("a", match: :first).click
    end
    expect(page).to have_content(DericciRecord.first.name)
  end

  it "should allow the user to create a new dericci record" do
    visit new_dericci_record_path
    fill_in "dericci_record_name", with: "Touissant L'Ouverture"
    find("#save-dericci").click
    expect(page).to have_content("Touissant L'Ouverture")
  end

  it "should allow an admin to add a verified link", :known_failure, :flaky do
    visit dericci_record_path(@d)
    expect(page).to have_content("Find Verified Name")
    open_verified_name_modal
    expect(page).to have_selector("#searchNameAuthority", visible: true)
    expect(page).to have_selector("#select-name-table", visible: true)
    expect(page).to have_content("Camillo")
    find(".selectName", visible: true, match: :first).click
    expect(page).not_to have_selector("#searchNameAuthority", visible: true)
    expect(page).to have_content("Camillo")
    expect(page).to have_selector("a.btn.btn-success.btn-xs", text: "Save")
    find("a.btn.btn-success.btn-xs", text: "Save").click
    expect(page).to have_content("Camillo")
  end

  it "should limit search to verified-linked or flagged records only" do
    visit dericci_records_path
    check "verified_id"
    find("#search-dericci").click
    expect(page).not_to have_content(@d.name)
    check "flagged"
    find("#search-dericci").click
    expect(page).to have_content('No matching records found.')
  end

  it "should allow an admin to remove verified link", :known_failure, :flaky do
    name = Name.find_by(name: "Camillo")
    DericciLink.create!(name: name, dericci_record: @d, approved: true, created_by: @user)

    visit dericci_record_path(@d)
    expect(page).to have_content("Camillo")
    click_link("Camillo")
    click_link("Remove Links")

    expect(page).to have_content("This name is not verifiably linked to any names in the SDBM Name Authority.")
  end

end
