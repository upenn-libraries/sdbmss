
require "rails_helper"

# There's JS on most of these pages. Not all features use JS, but
# there's no good reason NOT to use the js driver, so we do.
describe "Blacklight Advanced Search", :js => true do
  include SearchHelpers
  let_it_be(:admin_user) { create(:admin) }

  def rebuild_advanced_search_corpus!
    SampleIndexer.clear!
    Sunspot.index(Entry.all)
    Sunspot.commit
  end

  before :each do
    @user = admin_user
    Entry.create!({source: latest_seeded_source, created_by: @user})
    rebuild_advanced_search_corpus!
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

  def expect_result_membership(included:, excluded:)
    Array(included).each { |entry| expect(page).to have_link(entry.public_id) }
    Array(excluded).each { |entry| expect(page).not_to have_link(entry.public_id) }
  end

  it "should perform an empty search" do
    visit advanced_search_path

    find_by_id('advanced-search-submit').click

    expect(page).to have_content("You searched for:")
  end

  it "should do an advanced search using two Authors (ALL)" do
    matching_entry = create(:advanced_search_entry,
      title: "Advanced All Matching Entry",
      author: "Regression Augustine Hippo"
    )
    augustine_only = create(:advanced_search_entry,
      title: "Advanced All Augustine Only",
      author: "Regression Augustine Alone"
    )
    hippo_only = create(:advanced_search_entry,
      title: "Advanced All Hippo Only",
      author: "Regression Hippo Alone"
    )
    SampleIndexer.index_records!(matching_entry, augustine_only, hippo_only)

    perform_two_author_search

    filters = page.all('.appliedFilter')

    expect(filters.length).to eq(2)
    expect(filters[0].find('.filterValue')).to have_content("Augustine")
    expect(filters[1].find('.filterValue')).to have_content("Hippo")

    #check the count of results for this search against an AND search in a single field
    count = search_result_count
    expect_result_membership(included: matching_entry, excluded: [augustine_only, hippo_only])

    visit advanced_search_path

    search_fields = page.all(".advanced-search-field input[type=text]")
    search_fields[0].set "Augustine AND Hippo"

    select 'Author', from: "text_field_0"

    find_by_id('advanced-search-submit').click

    expect(page.find('.filterValue')).to have_content("Augustine AND Hippo")
    count2 = search_result_count
    expect_result_membership(included: matching_entry, excluded: [augustine_only, hippo_only])

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
    title_match = create(:advanced_search_entry,
      title: "Advanced Evil Title Match",
      author: "Regression Neutral Author"
    )
    author_match = create(:advanced_search_entry,
      title: "Advanced Neutral Title",
      author: "Regression Cicero"
    )
    non_match = create(:advanced_search_entry,
      title: "Advanced Neutral Excluded",
      author: "Regression Neutral Excluded"
    )
    SampleIndexer.index_records!(title_match, author_match, non_match)

    visit advanced_search_path

    search_fields = page.all(".advanced-search-field input[type=text]")
    search_fields[0].set "Cicero"
    search_fields[1].set "Evil"

    select 'Author', from: "text_field_0"
    select 'Title', from: "text_field_1"

    select 'any', from: 'op'

    find_by_id('advanced-search-submit').click

    # constraints are ordered by fieldname, not by how they were entered into search form

    filters = all('.appliedFilter')

    expect(filters[0]).to have_content('Any')
    expect(filters[1]).to have_content('Evil')
    expect(filters[2]).to have_content('Cicero')
    expect_result_membership(included: [title_match, author_match], excluded: non_match)
  end

  it "should do an advanced search using two Authors (ANY)" do
    augustine_entry = create(:advanced_search_entry,
      title: "Advanced Any Augustine",
      author: "Regression Augustine Any"
    )
    cicero_entry = create(:advanced_search_entry,
      title: "Advanced Any Cicero",
      author: "Regression Cicero Any"
    )
    non_match = create(:advanced_search_entry,
      title: "Advanced Any Excluded",
      author: "Regression Tacitus Any"
    )
    SampleIndexer.index_records!(augustine_entry, cicero_entry, non_match)

    visit advanced_search_path

    search_fields = page.all(".advanced-search-field input[type=text]")
    search_fields[0].set "Augustine"
    search_fields[1].set "Cicero"

    select 'Author', from: "text_field_0"
    select 'Author', from: "text_field_1"

    select 'any', from: 'op'

    find_by_id('advanced-search-submit').click

    expect(find('.appliedFilter', match: :first)).to have_content('Any')

    count = search_result_count
    expect_result_membership(included: [augustine_entry, cicero_entry], excluded: non_match)

    visit advanced_search_path

    search_fields = page.all(".advanced-search-field input[type=text]")
    search_fields[0].set "Augustine OR Cicero"

    select 'Author', from: "text_field_0"

    find_by_id('advanced-search-submit').click

    count2 = search_result_count
    expect_result_membership(included: [augustine_entry, cicero_entry], excluded: non_match)

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

    search_fields = page.all(".advanced-search-field input[type=text]")

    expect(search_fields[0].value).to eq("Augustine")
    expect(search_fields[1].value).to eq("Hippo")
  end

  it "should search for date range with single constraint" do
    matching_entry = create(:advanced_search_entry,
      title: "Advanced Date Range Match",
      manuscript_date: { observed: "ca. 1200", start: "1200", end: "1201" }
    )
    outside_entry = create(:advanced_search_entry,
      title: "Advanced Date Range Excluded",
      manuscript_date: { observed: "ca. 1900", start: "1900", end: "1901" }
    )
    SampleIndexer.index_records!(matching_entry, outside_entry)

    visit advanced_search_path

    fill_in "numeric_start_0", with: 100
    fill_in "numeric_end_0", with: 1800
    select "Manuscript Date", from: "numeric_field_0"

    find_by_id('advanced-search-submit').click

    filters = page.all('.appliedFilter')

    expect(filters.length).to eq(1)
    expect(filters[0].find('.filterValue')).to have_content("[100 TO 1800]")
    expect_result_membership(included: matching_entry, excluded: outside_entry)
  end

  it "should search for overlapping (ALL) numerical constraints" do
    matching_entry = create(:advanced_search_entry,
      title: "Advanced Overlap Match",
      manuscript_date: { observed: "ca. 1500", start: "1500", end: "1501" }
    )
    first_range_only = create(:advanced_search_entry,
      title: "Advanced Overlap First Range Only",
      manuscript_date: { observed: "ca. 500", start: "500", end: "501" }
    )
    second_range_only = create(:advanced_search_entry,
      title: "Advanced Overlap Second Range Only",
      manuscript_date: { observed: "ca. 1900", start: "1900", end: "1901" }
    )
    SampleIndexer.index_records!(matching_entry, first_range_only, second_range_only)

    visit advanced_search_path

    fill_in "numeric_start_0", with: 100
    fill_in "numeric_end_0", with: 1800
    select "Manuscript Date", from: "numeric_field_0"

    fill_in "numeric_start_1", with: 1000
    fill_in "numeric_end_1", with: 2000
    select "Manuscript Date", from: "numeric_field_1"

    find_by_id('advanced-search-submit').click

    filters = page.all('.appliedFilter')

    expect(filters.length).to eq(2)
    expect(filters[0].find('.filterValue')).to have_content("[100 TO 1800]")
    expect(filters[1].find('.filterValue')).to have_content("[1000 TO 2000]")

    # the results for overlapping dates should be the interior range

    count = search_result_count
    expect_result_membership(included: matching_entry, excluded: [first_range_only, second_range_only])

    visit advanced_search_path

    fill_in "numeric_start_0", with: 1000
    fill_in "numeric_end_0", with: 1800
    select "Manuscript Date", from: "numeric_field_0"

    find_by_id('advanced-search-submit').click

    count2 = search_result_count
    expect_result_membership(included: matching_entry, excluded: [first_range_only, second_range_only])

    expect(count).to eq(count2)
  end

  it "should search over ANY numerical constraints" do
    first_range_entry = create(:advanced_search_entry, title: "Advanced Any Folios One", folios: 1)
    second_range_entry = create(:advanced_search_entry, title: "Advanced Any Folios Three", folios: 3)
    outside_entry = create(:advanced_search_entry, title: "Advanced Any Folios Excluded", folios: 9)
    SampleIndexer.index_records!(first_range_entry, second_range_entry, outside_entry)

    visit advanced_search_path

    fill_in "numeric_start_0", with: 0
    fill_in "numeric_end_0", with: 1
    select "Folios", from: "numeric_field_0"
    fill_in "numeric_start_1", with: 2
    fill_in "numeric_end_1", with: 3
    select "Folios", from: "numeric_field_1"
    select 'any', from: 'op'

    find_by_id('advanced-search-submit').click

    filters = page.all('.appliedFilter')

    expect(filters[0]).to have_content("Any")

    count = search_result_count
    expect_result_membership(included: [first_range_entry, second_range_entry], excluded: outside_entry)

    visit advanced_search_path

    fill_in "numeric_start_0", with: 0
    fill_in "numeric_end_0", with: 3
    select "Folios", from: "numeric_field_0"
    find_by_id('advanced-search-submit').click

    count2 = search_result_count
    expect_result_membership(included: [first_range_entry, second_range_entry], excluded: outside_entry)

    expect(count).to eq(count2)
  end

  it "should find source date by complete Date string (YYYY-MM-DD)" do
    matching_entry = create(:advanced_search_entry,
      title: "Advanced Source Complete Date Match",
      source_date: "2015-01-01"
    )
    outside_entry = create(:advanced_search_entry,
      title: "Advanced Source Complete Date Excluded",
      source_date: "2016-01-01"
    )
    SampleIndexer.index_records!(matching_entry, outside_entry)

    visit advanced_search_path

    search_fields = page.all(".advanced-search-field input[type=text]")
    search_fields[0].set "2015-01-01"
    select 'Source Date', from: "text_field_0"
    find_by_id('advanced-search-submit').click

    count = search_result_count

    expect(count).not_to eq(0)
    expect_result_membership(included: matching_entry, excluded: outside_entry)
  end

  it "should find source date by incomplete Date strings (YYYY-MM), (YYYY)" do
    january_entry = create(:advanced_search_entry,
      title: "Advanced Source January Date Match",
      source_date: "2015-01-01"
    )
    december_entry = create(:advanced_search_entry,
      title: "Advanced Source December Date Match",
      source_date: "2015-12-31"
    )
    outside_entry = create(:advanced_search_entry,
      title: "Advanced Source Date Excluded",
      source_date: "2016-01-01"
    )
    SampleIndexer.index_records!(january_entry, december_entry, outside_entry)

    visit advanced_search_path

    search_fields = page.all(".advanced-search-field input[type=text]")
    search_fields[0].set "2015-01"
    select 'Source Date', from: "text_field_0"
    find_by_id('advanced-search-submit').click

    count = search_result_count
    expect(count).not_to eq(0)
    expect_result_membership(included: january_entry, excluded: [december_entry, outside_entry])

    visit advanced_search_path

    search_fields = page.all(".advanced-search-field input[type=text]")
    search_fields[0].set "2015"
    select 'Source Date', from: "text_field_0"
    find_by_id('advanced-search-submit').click

    count2 = search_result_count
    expect_result_membership(included: [january_entry, december_entry], excluded: outside_entry)

    expect(count).to be <= count2
  end

end
