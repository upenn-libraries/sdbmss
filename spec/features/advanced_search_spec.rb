
require 'json'
require "rails_helper"
require 'net/http'

# There's JS on most of these pages. Not all features use JS, but
# there's no good reason NOT to use the js driver, so we do.
describe "Blacklight Advanced Search", :js => true do

  before :all do
    # since we already have a set of reference data, we use that here
    # instead of creating another set of test data. The consequence is
    # that these tests don't exercise everything as thoroughly as they
    # should, but they're probably good enough.

#    SDBMSS::ReferenceData.create_all

    SDBMSS::Util.wait_for_solr_to_be_current

    @user = User.where(role: "admin").first
=begin
    User.create!(
      email: 'search@search.com',
      username: 'search',
      password: 'somethingunguessable',
    )
=end

    e = Entry.create!({source: Source.last, created_by: @user})
    e.index!
  end

  def doSearch ()
    visit advanced_search_path

    search_fields = page.all(".advanced-search-field input[type=text]")
    search_fields[0].set "Augustine"
    search_fields[1].set "Hippo"

    select 'Author', from: "text_field_0"
    select 'Author', from: "text_field_1"

    find_by_id('advanced-search-submit').click()
  end

  def countEntries ()
  	ct = find(".page_entries").text.match(/of\s(\d+)/)
  	if ct
  		return ct[1].to_i
  	else
  		return 0
  	end
  end

  it "should perform an empty search" do
  	visit advanced_search_path

  	find_by_id('advanced-search-submit').click()

  	expect(page).to have_content("You searched for:")
  end

  it "should do an advanced search using two Authors (ALL)" do
  	doSearch()

    filters = page.all('.appliedFilter')

    expect(filters.length).to eq(2)
    expect(filters[0].find('.filterValue')).to have_content("Augustine")
    expect(filters[1].find('.filterValue')).to have_content("Hippo")

    #check the count of results for this search against an AND search in a single field
   	count = countEntries

   	visit advanced_search_path

    search_fields = page.all(".advanced-search-field input[type=text]")
	search_fields[0].set "Augustine AND Hippo"

    select 'Author', from: "text_field_0"

    find_by_id('advanced-search-submit').click()

    expect(page.find('.filterValue')).to have_content("Augustine AND Hippo")
	count2 = countEntries

   	expect(count).to eq(count2)
  end


  it "should display list of Entries created by a given user" do
    visit advanced_search_path

    search_fields = page.all(".advanced-search-field input[type=text]")
    search_fields[0].set @user.username
    select 'Created By', from: "text_field_0"

    find_by_id('advanced-search-submit').click()

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

  	find_by_id('advanced-search-submit').click()

  	# constraints are ordered by fieldname, not by how they were entered into search form

  	filters = all('.appliedFilter')

  	expect(filters[0]).to have_content('Any')
  	expect(filters[1]).to have_content('Evil')
  	expect(filters[2]).to have_content('Cicero')
  end	

  it "should do an advanced search using two Authors (ANY)" do
  	visit advanced_search_path

  	search_fields = page.all(".advanced-search-field input[type=text]")
  	search_fields[0].set "Augustine"
  	search_fields[1].set "Cicero"

  	select 'Author', from: "text_field_0"
  	select 'Author', from: "text_field_1"

  	select 'any', from: 'op'

  	find_by_id('advanced-search-submit').click()

  	expect(first('.appliedFilter')).to have_content('Any')

  	count = countEntries

	visit advanced_search_path

  	search_fields = page.all(".advanced-search-field input[type=text]")
  	search_fields[0].set "Augustine OR Cicero"
  	
  	select 'Author', from: "text_field_0"

	find_by_id('advanced-search-submit').click()

	count2 = countEntries

	expect(count).to eq(count2)
  end

  it "should successfully remove a constraint" do
  	doSearch()

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
  	doSearch()

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

  	find_by_id('advanced-search-submit').click()

  	filters = page.all('.appliedFilter')

  	expect(filters.length).to eq(1)
  	expect(filters[0].find('.filterValue')).to have_content("[100 TO 1800]")
  end

  it "should search for overlapping (ALL) numerical constraints" do
  	visit advanced_search_path

  	fill_in "numeric_start_0", with: 100
  	fill_in "numeric_end_0", with: 1800
  	select "Manuscript Date", from: "numeric_field_0"

  	fill_in "numeric_start_1", with: 1000
  	fill_in "numeric_end_1", with: 2000
  	select "Manuscript Date", from: "numeric_field_1" 

  	find_by_id('advanced-search-submit').click()

  	filters = page.all('.appliedFilter')

  	expect(filters.length).to eq(2)
  	expect(filters[0].find('.filterValue')).to have_content("[100 TO 1800]")
  	expect(filters[1].find('.filterValue')).to have_content("[1000 TO 2000]")

  	# the results for overlapping dates should be the interior range

  	count = countEntries

  	visit advanced_search_path

  	fill_in "numeric_start_0", with: 1000
  	fill_in "numeric_end_0", with: 1800
  	select "Manuscript Date", from: "numeric_field_0"

  	find_by_id('advanced-search-submit').click()

  	count2 = countEntries

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

    find_by_id('advanced-search-submit').click()

    filters = page.all('.appliedFilter')

    expect(filters[0]).to have_content("Any")

    count = countEntries

    visit advanced_search_path

    fill_in "numeric_start_0", with: 0
    fill_in "numeric_end_0", with: 3
    select "Folios", from: "numeric_field_0"
    find_by_id('advanced-search-submit').click()

    count2 = countEntries

    expect(count).to eq(count2)
  end

  it "should find source date by complete Date string (YYYY-MM-DD)" do
    visit advanced_search_path

    search_fields = page.all(".advanced-search-field input[type=text]")
    search_fields[0].set "2015-01-01"
    select 'Source Date', from: "text_field_0"
    find_by_id('advanced-search-submit').click()

    count = countEntries

    expect(count).not_to eq(0)
  end

  it "should find source date by incomplete Date strings (YYYY-MM), (YYYY)" do
    visit advanced_search_path

    search_fields = page.all(".advanced-search-field input[type=text]")
    search_fields[0].set "2015-01"
    select 'Source Date', from: "text_field_0"
    find_by_id('advanced-search-submit').click()

    count = countEntries
    expect(count).not_to eq(0)

    visit advanced_search_path

    search_fields = page.all(".advanced-search-field input[type=text]")
    search_fields[0].set "2015"
    select 'Source Date', from: "text_field_0"
    find_by_id('advanced-search-submit').click()

    count2 = countEntries

    expect(count).to be <= count2
  end

end