
require "rails_helper"

# There's JS on most of these pages. Not all features use JS, but
# there's no good reason NOT to use the js driver, so we do.
describe "Blacklight Advanced Search", :js => true do
  include SearchHelpers
  let(:admin_user) { create(:admin) }

  before :each do
    @user = admin_user
    e = Entry.create!({source: latest_seeded_source, created_by: @user})
    e.index!
  end

  def perform_two_author_search
    visit advanced_search_path

    search_fields = page.all(".advanced-search-field input[type=text]")
    search_fields[0].set "Augustine"
    search_fields[1].set "Hippo"

    select 'Author', from: "text_field_0"
    select 'Author', from: "text_field_1"

    find_by_id('advanced-search-submit').click
  end

  it "should perform an empty search" do
    visit advanced_search_path

    find_by_id('advanced-search-submit').click

    expect(page).to have_css('#appliedParams')
  end

  it "should do an advanced search using two Authors (ALL)" do
    perform_two_author_search

    filters = page.all('.applied-filter')

    expect(filters.length).to eq(2)
    expect(filters[0].find('.filter-value')).to have_content("Augustine")
    expect(filters[1].find('.filter-value')).to have_content("Hippo")

    #check the count of results for this search against an AND search in a single field
    count = search_result_count

    visit advanced_search_path

    search_fields = page.all(".advanced-search-field input[type=text]")
    search_fields[0].set "Augustine AND Hippo"

    select 'Author', from: "text_field_0"

    find_by_id('advanced-search-submit').click

    expect(page.find('.filter-value')).to have_content("Augustine AND Hippo")
    count2 = search_result_count

    expect(count).to eq(count2)
  end


  it "should display list of Entries created by a given user" do
    visit advanced_search_path

    search_fields = page.all(".advanced-search-field input[type=text]")
    search_fields[0].set @user.username
    select 'Added By', from: "text_field_0"

    find_by_id('advanced-search-submit').click

    expect(page).to have_content(@user.entries.last.public_id)
  end

  it "should do an advanced search using Title + Author (ANY)" do
    visit advanced_search_path

    search_fields = page.all(".advanced-search-field input[type=text]")
    search_fields[0].set "Cicero"
    search_fields[1].set "Evil"

    select 'Author', from: "text_field_0"
    select 'Title', from: "text_field_1"

    select 'any', from: 'op'

    find_by_id('advanced-search-submit').click

    # constraints are ordered by fieldname, not by how they were entered into search form

    filters = all('.applied-filter')

    filter_texts = filters.map(&:text)
    expect(filter_texts.any? { |t| t.include?('Evil') }).to be true
    expect(filter_texts.any? { |t| t.include?('Cicero') }).to be true
  end

  it "should do an advanced search using two Authors (ANY)" do
    visit advanced_search_path

    search_fields = page.all(".advanced-search-field input[type=text]")
    search_fields[0].set "Augustine"
    search_fields[1].set "Cicero"

    select 'Author', from: "text_field_0"
    select 'Author', from: "text_field_1"

    select 'any', from: 'op'

    find_by_id('advanced-search-submit').click

    expect(page).to have_css('.applied-filter')

    count = search_result_count

    visit advanced_search_path

    search_fields = page.all(".advanced-search-field input[type=text]")
    search_fields[0].set "Augustine OR Cicero"

    select 'Author', from: "text_field_0"

    find_by_id('advanced-search-submit').click

    count2 = search_result_count

    expect(count).to eq(count2)
  end

  it "should successfully remove a constraint" do
    perform_two_author_search

    filters = page.all('.applied-filter')

    expect(filters.length).to eq(2)
    expect(filters[0].find('.filter-value')).to have_content("Augustine")
    expect(filters[1].find('.filter-value')).to have_content("Hippo")

    filters[0].find('.remove').click()

    filters = page.all('.applied-filter')
    expect(filters.length).to eq(1)
    expect(filters[0].find('.filter-value')).to have_content("Hippo")
  end

  it "should repopulate the advanced search fields with selected constraints" do
    perform_two_author_search

    page.find('a.advanced_search').click()

    search_fields = page.all(".advanced-search-field input[type=text]")

    expect(search_fields[0].value).to eq("Augustine")
    expect(search_fields[1].value).to eq("Hippo")
  end

  it "should search for date range with single constraint" do
    visit advanced_search_path

    fill_in "numeric_start_0", with: 100
    fill_in "numeric_end_0", with: 1800
    select "Manuscript Date", from: "numeric_field_0"

    find_by_id('advanced-search-submit').click

    filters = page.all('.applied-filter')

    expect(filters.length).to eq(1)
    expect(filters[0].find('.filter-value')).to have_content("[100 TO 1800]")
  end

  it "should search for overlapping (ALL) numerical constraints" do
    visit advanced_search_path

    fill_in "numeric_start_0", with: 100
    fill_in "numeric_end_0", with: 1800
    select "Manuscript Date", from: "numeric_field_0"

    fill_in "numeric_start_1", with: 1000
    fill_in "numeric_end_1", with: 2000
    select "Manuscript Date", from: "numeric_field_1"

    find_by_id('advanced-search-submit').click

    filters = page.all('.applied-filter')

    expect(filters.length).to eq(2)
    expect(filters[0].find('.filter-value')).to have_content("[100 TO 1800]")
    expect(filters[1].find('.filter-value')).to have_content("[1000 TO 2000]")

    # the results for overlapping dates should be the interior range

    count = search_result_count

    visit advanced_search_path

    fill_in "numeric_start_0", with: 1000
    fill_in "numeric_end_0", with: 1800
    select "Manuscript Date", from: "numeric_field_0"

    find_by_id('advanced-search-submit').click

    count2 = search_result_count

    expect(count).to eq(count2)
  end

  it "should search over ANY numerical constraints" do
    visit advanced_search_path

    fill_in "numeric_start_0", with: 0
    fill_in "numeric_end_0", with: 1
    select "Folios", from: "numeric_field_0"
    fill_in "numeric_start_1", with: 2
    fill_in "numeric_end_1", with: 3
    select "Folios", from: "numeric_field_1"
    select 'any', from: 'op'

    find_by_id('advanced-search-submit').click

    filters = page.all('.applied-filter')

    expect(page).to have_css('.applied-filter')

    count = search_result_count

    visit advanced_search_path

    fill_in "numeric_start_0", with: 0
    fill_in "numeric_end_0", with: 3
    select "Folios", from: "numeric_field_0"
    find_by_id('advanced-search-submit').click

    count2 = search_result_count

    expect(count).to eq(count2)
  end

  it "should find source date by complete Date string (YYYY-MM-DD)" do
    visit advanced_search_path

    search_fields = page.all(".advanced-search-field input[type=text]")
    search_fields[0].set "2015-01-01"
    select 'Source Date', from: "text_field_0"
    find_by_id('advanced-search-submit').click

    count = search_result_count

    expect(count).not_to eq(0)
  end

  it "should find source date by incomplete Date strings (YYYY-MM), (YYYY)" do
    visit advanced_search_path

    search_fields = page.all(".advanced-search-field input[type=text]")
    search_fields[0].set "2015-01"
    select 'Source Date', from: "text_field_0"
    find_by_id('advanced-search-submit').click

    count = search_result_count
    expect(count).not_to eq(0)

    visit advanced_search_path

    search_fields = page.all(".advanced-search-field input[type=text]")
    search_fields[0].set "2015"
    select 'Source Date', from: "text_field_0"
    find_by_id('advanced-search-submit').click

    count2 = search_result_count

    expect(count).to be <= count2
  end

end
