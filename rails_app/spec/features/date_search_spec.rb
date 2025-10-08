
require 'json'
require "system_helper"
require 'net/http'

# Test manuscript date search in Solr, mostly to verify end-exclusive
# date ranges work as expected. This is separate from other search
# tests because we use a different set of test data.
describe "Date Search", :js => true do

  before :all do
    user = User.where(username: "lransom").first
=begin
    user = User.create!(
      username: "lransom",
      email: "lransom@upenn.edu",
      password: "12345678",
      password_confirmation: "12345678"
    )
=end    
    source = Source.create!(
      source_type: SourceType.auction_catalog,
      date: "20150101",
      title: "Test catalog",
      whether_mss: Source::TYPE_HAS_MANUSCRIPT_YES,
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
      created_by: user,
      approved: true
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
      created_by: user,
      approved: true
    )

    SDBMSS::Util.wait_for_solr_to_be_current

    #expect(Entry.all.count).to eq(2)
  end

  def date_search start_date, end_date, num_expected_results
    visit advanced_search_path
    if start_date.present?
      fill_in 'numeric_start_0', with: start_date
    end
    if end_date.present?
      fill_in 'numeric_end_0', with: end_date
    end
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(all(".document").length).to eq(num_expected_results)
  end

  it "should handle entry_date with range 1900-1950" do

    # search for single dates outside range

    date_search "1899", "1899", 0
    date_search "1951", "1951", 0

    # search for single dates that fall inside range

    date_search "1900", "1900", 1
    date_search "1921", "1921", 1
    date_search "1950", "1950", 1

    # search for ranges that intersect

    date_search "1875", "1900", 1
    date_search "1910", "1915", 1
    date_search "1950", "1960", 1

    # search for ranges that DON'T intersect

    date_search "1800", "1899", 0
    date_search "1951", "1960", 0

    # searches with infinity on one side

    date_search "1890", nil, 1
    date_search "1900", nil, 1
    date_search "1950", nil, 1
    date_search "1951", nil, 0
    date_search nil, "1899", 10
    date_search nil, "1900", 10
    date_search nil, "1950", 10
    date_search nil, "1960", 10
  end

  it "should handle entry_date with exact date 1502" do

    # search for exact match and exact non-match

    date_search "1501", "1501", 2
    date_search "1502", "1502", 3
    date_search "1503", "1503", 2

    # search for range that intersects

    date_search "1475", "1502", 5
    date_search "1475", "1550", 5
    date_search "1502", "1510", 3

    # search for range that doesn't intersect

    date_search "1400", "1501", 10
    date_search "1503", "1510", 2
  end

end
