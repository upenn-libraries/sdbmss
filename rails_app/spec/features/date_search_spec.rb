require 'rails_helper'

describe 'Date Search', js: true do
  before do
    SampleIndexer.clear!
    Sunspot.index(Entry.all)
    user = User.find_by(username: 'lransom')
    source = Source.create!(
      source_type: SourceType.auction_catalog,
      date: '20150101',
      title: 'Test catalog',
      whether_mss: Source::TYPE_HAS_MANUSCRIPT_YES,
      medium: Source::TYPE_MEDIUM_INTERNET,
      created_by: user
    )
    entries = [
      { observed_date: '1900 to 1950', date_normalized_start: '1900', date_normalized_end: '1951' },
      { observed_date: '1502',         date_normalized_start: '1502', date_normalized_end: '1503' }
    ].map do |date_attrs|
      Entry.create!(
        source: source,
        catalog_or_lot_number: '1',
        transaction_type: Entry::TYPE_TRANSACTION_SALE,
        entry_dates_attributes: [date_attrs],
        created_by: user,
        approved: true
      )
    end
    @range_entry = entries.first
    Sunspot.commit
  end

  it 'submits manuscript date constraints from advanced search UI' do
    visit advanced_search_path

    fill_in 'numeric_start_0', with: '1900'
    fill_in 'numeric_end_0', with: '1900'
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(page).to have_current_path(/search_field=advanced/)
    expect(page).to have_content(@range_entry.public_id)

    visit advanced_search_path
    fill_in 'numeric_start_0', with: '1951'
    fill_in 'numeric_end_0', with: '1951'
    select 'Manuscript Date', from: 'numeric_field_0'
    click_button('advanced-search-submit')

    expect(page).to have_content('No results found')
  end
end
