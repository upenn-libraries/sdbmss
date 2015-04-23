
require 'json'
require "rails_helper"
require 'net/http'

# Test manuscript date search in Solr, mostly to verify end-exclusive date ranges work as expected
describe "Date Search", :js => true do

  it "should search" do
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
    entry = Entry.create!(
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

    SDBMSS::Util.wait_for_solr_to_be_current

    expect(Entry.all.count).to eq(1)

    # test a whole bunch of range searches on date

    visit advanced_search_path
    fill_in 'numeric_start_0', with: "1899"
    fill_in 'numeric_end_0', with: "1899"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(0)

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

    visit advanced_search_path
    fill_in 'numeric_start_0', with: "1875"
    fill_in 'numeric_end_0', with: "1900"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(1)

    visit advanced_search_path
    fill_in 'numeric_start_0', with: "1950"
    fill_in 'numeric_end_0', with: "1960"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(1)

    visit advanced_search_path
    fill_in 'numeric_start_0', with: "1951"
    fill_in 'numeric_end_0', with: "1960"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(0)

    visit advanced_search_path

    fill_in 'numeric_start_0', with: "1951"
    fill_in 'numeric_end_0', with: "1951"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(0)

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

    expect(all(".document").length).to eq(0)

    visit advanced_search_path
    fill_in 'numeric_end_0', with: "1900"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(1)

    visit advanced_search_path
    fill_in 'numeric_end_0', with: "1950"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(1)

    visit advanced_search_path
    fill_in 'numeric_end_0', with: "1960"
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(1)

  end

end
