
require 'json'
require "rails_helper"
require 'net/http'

# Test manuscript date search in Solr, mostly to verify end-exclusive date ranges work as expected
describe "Date Search", :js => true do

  before :all do
    user = User.create!(
      username: "lransom",
      email: "lransom@upenn.edu",
      password: "12345678",
      password_confirmation: "12345678"
    )
    source = Source.create!(
      source_type: SourceType.auction_catalog,
      date: "20150101",
      title: "Catalogue 213: Fine and Important Manuscripts and Printed Books",
      whether_mss: Source::TYPE_HAS_MANUSCRIPT_YES,
      link: "https://www.jonathanahill.com/lists/HomePageFiles/Cat%20213%20unillustrated%20proofs.pdf",
      medium: Source::TYPE_MEDIUM_INTERNET,
      created_by: user,
    )

    Entry.create!(
      source: source,
      catalog_or_lot_number: "1",
      transaction_type: Entry::TYPE_TRANSACTION_SALE,
      entry_dates_attributes: [
        {
          observed_date: "1900 to 1950",
          date_normalized_start: "1900",
          date_normalized_end: "1951",
        },
      ],
      created_by: user
    )

    Entry.create!(
      source: source,
      catalog_or_lot_number: "1",
      transaction_type: Entry::TYPE_TRANSACTION_SALE,
      entry_dates_attributes: [
        {
          observed_date: "1502",
          date_normalized_start: "1502",
          date_normalized_end: "1503",
        },
      ],
      created_by: user
    )

    SDBMSS::Util.wait_for_solr_to_be_current

    expect(Entry.all.count).to eq(2)

  end

  it "should handle entry_date with range 1900-1950" do

    # search for single dates outside range

    visit advanced_search_path
    fill_in 'numeric_start_0', with: "1899"
    fill_in 'numeric_end_0', with: "1899"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(0)

    visit advanced_search_path
    fill_in 'numeric_start_0', with: "1951"
    fill_in 'numeric_end_0', with: "1951"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(0)

    # search for single dates that fall inside range

    visit advanced_search_path
    fill_in 'numeric_start_0', with: "1900"
    fill_in 'numeric_end_0', with: "1900"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(1)

    visit advanced_search_path
    fill_in 'numeric_start_0', with: "1950"
    fill_in 'numeric_end_0', with: "1950"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(1)

    # search for ranges that intersect

    visit advanced_search_path
    fill_in 'numeric_start_0', with: "1875"
    fill_in 'numeric_end_0', with: "1900"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(1)

    visit advanced_search_path
    fill_in 'numeric_start_0', with: "1910"
    fill_in 'numeric_end_0', with: "1915"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(1)

    visit advanced_search_path
    fill_in 'numeric_start_0', with: "1950"
    fill_in 'numeric_end_0', with: "1960"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(1)

    # search for ranges that DON'T intersect

    visit advanced_search_path
    fill_in 'numeric_start_0', with: "1951"
    fill_in 'numeric_end_0', with: "1960"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(0)

    visit advanced_search_path

    # searches with infinity on one side

    visit advanced_search_path
    fill_in 'numeric_start_0', with: "1890"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(1)

    visit advanced_search_path
    fill_in 'numeric_start_0', with: "1900"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(1)

    visit advanced_search_path
    fill_in 'numeric_start_0', with: "1950"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(1)

    visit advanced_search_path
    fill_in 'numeric_start_0', with: "1951"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(0)

    visit advanced_search_path
    fill_in 'numeric_end_0', with: "1899"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(1)

    visit advanced_search_path
    fill_in 'numeric_end_0', with: "1900"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(2)

    visit advanced_search_path
    fill_in 'numeric_end_0', with: "1950"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(2)

    visit advanced_search_path
    fill_in 'numeric_end_0', with: "1960"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(2)
  end

  it "should handle entry_date with exact date 1502" do

    # search for non-matching exact dates

    visit advanced_search_path
    fill_in 'numeric_start_0', with: "1501"
    fill_in 'numeric_end_0', with: "1501"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(0)

    visit advanced_search_path
    fill_in 'numeric_start_0', with: "1503"
    fill_in 'numeric_end_0', with: "1503"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(0)

    # search for exact match

    visit advanced_search_path
    fill_in 'numeric_start_0', with: "1502"
    fill_in 'numeric_end_0', with: "1502"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(1)

    # search for range that intersects

    visit advanced_search_path
    fill_in 'numeric_start_0', with: "1475"
    fill_in 'numeric_end_0', with: "1502"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(1)

    visit advanced_search_path
    fill_in 'numeric_start_0', with: "1475"
    fill_in 'numeric_end_0', with: "1550"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(1)

    visit advanced_search_path
    fill_in 'numeric_start_0', with: "1502"
    fill_in 'numeric_end_0', with: "1510"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(1)

    # search for range that doesn't intersect

    visit advanced_search_path
    fill_in 'numeric_start_0', with: "1400"
    fill_in 'numeric_end_0', with: "1501"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(0)

    visit advanced_search_path
    fill_in 'numeric_start_0', with: "1503"
    fill_in 'numeric_end_0', with: "1510"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(0)

  end

end
