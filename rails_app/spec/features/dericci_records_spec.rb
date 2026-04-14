
require 'json'
require "rails_helper"

describe "Browse Dericci Records", :js => true do
  let(:admin_user) { create(:admin) }

  def create_dericci_record(name, place:, dates:)
    DericciRecord.find_or_create_by(name: name) do |record|
      record.place = place
      record.dates = dates
      record.senate_house = "[Senate House MS901/3/11]"
    end
  end

  def expect_record_names(records)
    records.each do |record|
      expect(page).to have_content(record.name)
    end
  end

  def open_verified_name_modal
    3.times do
      find("#verify", visible: true).trigger("click")
      return if page.has_selector?("#searchNameAuthority", visible: true, wait: 2)
    end

    raise Capybara::ElementNotFound, "Verified-name modal did not open"
  end

  before :each do
    @d = create_dericci_record("Camille Desmoulins", place: "Paris", dates: "1794")

    # Reset mutable state: sibling tests may have added links/flags or set verified_id.
    @d.update!(verified_id: nil)
    @d.dericci_links.destroy_all
    @d.dericci_record_flags.destroy_all

    Name.find_or_create_by(name: "Camillo") { |n| n.is_author = true }.index
    Name.find_or_create_by(name: "George Danton") { |n| n.is_author = true }.index
    Sunspot.commit
  end

  before :each do
    login(admin_user, "somethingreallylong")
  end

  after :each do
    page.reset!
  end

  it "should display an empty search of collectors/repositories" do
    visit dericci_records_path

    expect_record_names(DericciRecord.order(:id).limit(15))
  end

  it "should display the results for the correct alphabatized letter page" do
    visit dericci_records_path
    click_link "G"

    expect_record_names(DericciRecord.where("name like ?", "G%").order(:id).limit(15))
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
    first_record = DericciRecord.order(:id).first

    visit dericci_records_path
    within ".sdbm-table" do
      first("a").click
    end
    expect(page).to have_content(first_record.name)
  end

  it "should allow the user to create a new dericci record" do
    visit new_dericci_record_path
    fill_in "dericci_record_name", with: "Touissant L'Ouverture"
    find("#save-dericci").click
    expect(page).to have_content("Touissant L'Ouverture")
  end

  it "should allow an admin to add a verified link" do
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
    skip "the behavior around verified_id and the unverified checkbox is confusing, should be fixed as a real bug fix"
    visit dericci_records_path
    check "verified_id"
    find("#search-dericci").click
    expect(page).not_to have_content(@d.name)
    check "flagged"
    find("#search-dericci").click
    expect(page).to have_content('No matching records found.')
  end

  it "should allow an admin to remove verified link" do
    name = Name.find_by(name: "Camillo")
    DericciLink.create!(name: name, dericci_record: @d, approved: true, created_by: admin_user)

    visit dericci_record_path(@d)
    expect(page).to have_content("Camillo")
    click_link("Camillo")
    click_link("Remove Links")

    expect(page).to have_content("This name is not verifiably linked to any names in the SDBM Name Authority.")
  end

end
