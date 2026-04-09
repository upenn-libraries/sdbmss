
require "rails_helper"

# There's JS on most of these pages. Not all features use JS, but
# there's no good reason NOT to use the js driver, so we do.
describe "Blacklight Advanced Search", :js => true do
  include SearchHelpers

  before :each do
    @user = User.where(role: "admin").first
    e = Entry.create!({source: latest_seeded_source, created_by: @user})
    e.index!
  end

  def perform_two_author_search
    open_blacklight_advanced_search

    search_fields = advanced_search_text_fields
    search_fields[0].set "Augustine"
    search_fields[1].set "Hippo"

    select 'Author', from: "text_field_0"
    select 'Author', from: "text_field_1"

    submit_blacklight_advanced_search
  end

  it "should perform an empty search" do
    open_blacklight_advanced_search

    submit_blacklight_advanced_search

    expect(page).to have_content("You searched for:")
  end

  it "should do an advanced search using two Authors (ALL)" do
    perform_two_author_search

    filters = page.all('.appliedFilter')

    expect(filters.length).to eq(2)
    expect(filters[0].find('.filterValue')).to have_content("Augustine")
    expect(filters[1].find('.filterValue')).to have_content("Hippo")

    #check the count of results for this search against an AND search in a single field
    count = search_result_count

    open_blacklight_advanced_search

    search_fields = advanced_search_text_fields
    search_fields[0].set "Augustine AND Hippo"

    select 'Author', from: "text_field_0"

    submit_blacklight_advanced_search

    expect(page.find('.filterValue')).to have_content("Augustine AND Hippo")
    count2 = search_result_count

    expect(count).to eq(count2)
  end


  it "should display list of Entries created by a given user" do
    open_blacklight_advanced_search

    search_fields = advanced_search_text_fields
    search_fields[0].set @user.username
    select 'Added By', from: "text_field_0"

    submit_blacklight_advanced_search

    expect(page).to have_content(@user.entries.last.public_id)
  end

  it "should do an advanced search using Title + Author (ANY)" do
    open_blacklight_advanced_search

    search_fields = advanced_search_text_fields
    search_fields[0].set "Cicero"
    search_fields[1].set "Evil"

    select 'Author', from: "text_field_0"
    select 'Title', from: "text_field_1"

    select 'any', from: 'op'

    submit_blacklight_advanced_search

    # constraints are ordered by fieldname, not by how they were entered into search form

    filters = all('.appliedFilter')

    expect(filters[0]).to have_content('Any')
    expect(filters[1]).to have_content('Evil')
    expect(filters[2]).to have_content('Cicero')
  end

  it "should do an advanced search using two Authors (ANY)" do
    open_blacklight_advanced_search

    search_fields = advanced_search_text_fields
    search_fields[0].set "Augustine"
    search_fields[1].set "Cicero"

    select 'Author', from: "text_field_0"
    select 'Author', from: "text_field_1"

    select 'any', from: 'op'

    submit_blacklight_advanced_search

    expect(find('.appliedFilter', match: :first)).to have_content('Any')

    count = search_result_count

    open_blacklight_advanced_search

    search_fields = advanced_search_text_fields
    search_fields[0].set "Augustine OR Cicero"

    select 'Author', from: "text_field_0"

    submit_blacklight_advanced_search

    count2 = search_result_count

    expect(count).to eq(count2)
  end

  it "should successfully remove a constraint" do
    perform_two_author_search

    filters = page.all('.appliedFilter')

    expect(filters.length).to eq(2)
    expect(filters[0].find('.filterValue')).to have_content("Augustine")
    expect(filters[1].find('.filterValue')).to have_content("Hippo")

    filters[0].find('.remove').click()

    filters = page.all('.appliedFilter')
    expect(filters.length).to eq(1)
    expect(filters[0].find('.filterValue')).to have_content("Hippo")
  end

  it "should repopulate the advanced search fields with selected constraints" do
    perform_two_author_search

    page.find('a.advanced_search').click()

    search_fields = advanced_search_text_fields

    expect(search_fields[0].value).to eq("Augustine")
    expect(search_fields[1].value).to eq("Hippo")
  end

  it "should search for date range with single constraint" do
    open_blacklight_advanced_search

    fill_in "numeric_start_0", with: 100
    fill_in "numeric_end_0", with: 1800
    select "Manuscript Date", from: "numeric_field_0"

    submit_blacklight_advanced_search

    filters = page.all('.appliedFilter')

    expect(filters.length).to eq(1)
    expect(filters[0].find('.filterValue')).to have_content("[100 TO 1800]")
  end

  it "should search for overlapping (ALL) numerical constraints" do
    open_blacklight_advanced_search

    fill_in "numeric_start_0", with: 100
    fill_in "numeric_end_0", with: 1800
    select "Manuscript Date", from: "numeric_field_0"

    fill_in "numeric_start_1", with: 1000
    fill_in "numeric_end_1", with: 2000
    select "Manuscript Date", from: "numeric_field_1"

    submit_blacklight_advanced_search

    filters = page.all('.appliedFilter')

    expect(filters.length).to eq(2)
    expect(filters[0].find('.filterValue')).to have_content("[100 TO 1800]")
    expect(filters[1].find('.filterValue')).to have_content("[1000 TO 2000]")

    # the results for overlapping dates should be the interior range

    count = search_result_count

    open_blacklight_advanced_search

    fill_in "numeric_start_0", with: 1000
    fill_in "numeric_end_0", with: 1800
    select "Manuscript Date", from: "numeric_field_0"

    submit_blacklight_advanced_search

    count2 = search_result_count

    expect(count).to eq(count2)
  end

  it "should search over ANY numerical constraints" do
    open_blacklight_advanced_search

    fill_in "numeric_start_0", with: 0
    fill_in "numeric_end_0", with: 1
    select "Folios", from: "numeric_field_0"
    fill_in "numeric_start_1", with: 2
    fill_in "numeric_end_1", with: 3
    select "Folios", from: "numeric_field_1"
    select 'any', from: 'op'

    submit_blacklight_advanced_search

    filters = page.all('.appliedFilter')

    expect(filters[0]).to have_content("Any")

    count = search_result_count

    open_blacklight_advanced_search

    fill_in "numeric_start_0", with: 0
    fill_in "numeric_end_0", with: 3
    select "Folios", from: "numeric_field_0"
    submit_blacklight_advanced_search

    count2 = search_result_count

    expect(count).to eq(count2)
  end

  it "should find source date by complete Date string (YYYY-MM-DD)" do
    open_blacklight_advanced_search

    search_fields = advanced_search_text_fields
    search_fields[0].set "2015-01-01"
    select 'Source Date', from: "text_field_0"
    submit_blacklight_advanced_search

    count = search_result_count

    expect(count).not_to eq(0)
  end

  it "should find source date by incomplete Date strings (YYYY-MM), (YYYY)" do
    open_blacklight_advanced_search

    search_fields = advanced_search_text_fields
    search_fields[0].set "2015-01"
    select 'Source Date', from: "text_field_0"
    submit_blacklight_advanced_search

    count = search_result_count
    expect(count).not_to eq(0)

    open_blacklight_advanced_search

    search_fields = advanced_search_text_fields
    search_fields[0].set "2015"
    select 'Source Date', from: "text_field_0"
    submit_blacklight_advanced_search

    count2 = search_result_count

    expect(count).to be <= count2
  end

end
