
require "rails_helper"

# There's JS on most of these pages. Not all features use JS, but
# there's no good reason NOT to use the js driver, so we do.
describe "Blacklight Search", :js => true do
  include SearchHelpers
  let(:admin_user) { create(:admin) }

  def create_search_entry(title:, author:, catalog_number:, height: nil)
    source = Source.create!(
      title: "Source for #{title}",
      source_type: SourceType.auction_catalog,
      created_by: @user
    )
    entry_attributes = {
      source: source,
      created_by: @user,
      approved: true,
      catalog_or_lot_number: catalog_number
    }
    entry_attributes[:height] = height if height.present?

    entry = Entry.create!(entry_attributes)
    entry.entry_titles.create!(title: title, order: 0)
    entry.entry_authors.create!(author: Name.find_or_create_agent(author), order: 0)
    entry
  end

  def author_facet_corpus
    [
      create_search_entry(title: "Author Corpus A", author: "Augustine", catalog_number: "A1"),
      create_search_entry(title: "Author Corpus B", author: "Bernard", catalog_number: "B1"),
      create_search_entry(title: "Author Corpus C", author: "Cicero", catalog_number: "C1"),
      create_search_entry(title: "Author Corpus D", author: "Dokeianos", catalog_number: "D1"),
      create_search_entry(title: "Author Corpus E", author: "Erasmus", catalog_number: "E1"),
      create_search_entry(title: "Author Corpus F", author: "Francis", catalog_number: "F1"),
      create_search_entry(title: "Author Corpus G", author: "Gregory", catalog_number: "G1")
    ]
  end

  before :all do
    # since we already have a set of reference data, we use that here
    # instead of creating another set of test data. The consequence is
    # that these tests don't exercise everything as thoroughly as they
    # should, but they're probably good enough.

#    SDBMSS::ReferenceData.create_all

    SDBMSS::Util.wait_for_solr_to_be_current
  end

  before :each do
    @user = admin_user
  end

  it "should load main landing page" do
    visit root_path
    expect(page).to have_selector("input#q")
  end

  it "should show my public entries" do
    login(@user, 'somethingreallylong')

    source = Source.create!(
      title: "Test Source for Public Entries",
      source_type: SourceType.auction_catalog,
      created_by: @user
    )
    e = Entry.create!(source: source, created_by: @user, approved: true)
    e.index!

    visit dashboard_contributions_path
    find_link("See Your Public Entries").trigger("click")

    expect(page).to have_content(e.public_id)
  end

  it "should display all entries", :solr do
    entries = author_facet_corpus
    SampleIndexer.index_records!(entries)

    visit root_path
    click_button('search')
    expect(page).to have_selector("#documents")

    entries.each do |entry|
      expect(page).to have_link(entry.public_id)
    end

    # now need to be logged in to export to csv!
    #expect(page).to have_selector(".export-csv")
  end

  it "should display results for an Author facet", :solr do
    SampleIndexer.index_records!(author_facet_corpus)

    visit root_path
    click_button('search')
    expect(page).to have_selector("#documents")

    find(:css, "#facet-author .facet-values a", match: :first).click
    expect(page).to have_selector("#documents")
  end

  it "should display list of Author facet values", :solr do
    SampleIndexer.index_records!(author_facet_corpus)

    visit root_path
    click_button('search')
    expect(page).to have_selector("#documents")

    find(:css, ".more_facets_link a", match: :first).click

    expect(page).to have_content "Browsing facet: Author"

    find(:css, ".az", match: :first).click

    expect(page).to have_content "Browsing facet: Author"
    expect(page).to have_content "Prefix"

    click_link("D")

    expect(page).to have_content "Browsing facet: Author"
    expect(page).not_to have_content "Augustine"
    expect(page).to have_content "Dokeianos"
  end

  # this test disabled because we removed the search field dropdown
  # it "should search on Provenance" do
  #   visit root_path
  #   select "Provenance", from: "search_field"
  #   fill_in "q", with: "Tomkinson"
  #   click_button('search')

  #   entry_one = get_hill_entry_by_cat_num(1)
  #   entry_nine = get_hill_entry_by_cat_num(9)

  #   expect(page).to have_link(entry_one.public_id)
  #   expect(page).not_to have_link(entry_nine.public_id)
  # end

  it "should load advanced search page" do
    visit advanced_search_path

    search_fields = CatalogController.blacklight_config.search_fields.values

    # all text search fields should show up in dropdown
    expect(find_by_id('text_field_0').all("option", visible: :all).length).to eq(
      search_fields.count { |field_def| !field_def.is_numeric_field && field_def.include_in_advanced_search != false }
    )
    # all numeric search fields should show up in dropdown
    expect(find_by_id('numeric_field_0').all("option", visible: :all).length).to eq(
      search_fields.count { |field_def| field_def.is_numeric_field && field_def.include_in_advanced_search != false }
    )
  end

  it "should do advanced search using numeric range on Height", :solr do
    entry_one = create_search_entry(
      title: "Height Search One",
      author: "Height Author One",
      catalog_number: "H1",
      height: 251
    )
    entry_two = create_search_entry(
      title: "Height Search Two",
      author: "Height Author Two",
      catalog_number: "H2",
      height: 259
    )
    SampleIndexer.index_records!(entry_one, entry_two)

    visit advanced_search_path

    fill_in "numeric_start_0", with: 250
    fill_in "numeric_end_0", with: 260
    select "Height", from: "numeric_field_0"

    find_by_id('advanced-search-submit').click

    expect(page).to have_link(entry_one.public_id)
    expect(page).to have_link(entry_two.public_id)
  end

  it "should load show Entry page", :solr do
    entry = create_search_entry(
      title: "Direct Show Entry",
      author: "Direct Show Author",
      catalog_number: "SHOW1"
    )
    SampleIndexer.index_records!(entry)

    visit entry_path(entry)
    expect(page).to have_xpath("//h1[contains(.,'#{entry.public_id}')]")
  end

  it "should 404 on show Entry page for deleted entry" do
    entry = Entry.new(
      source: latest_seeded_source,
      deleted: true
    )
    entry.save!
    SDBMSS::Util.wait_for_solr_to_be_current

    visit entry_path(entry)
    expect(page.status_code).to eq(404)
  end

  it "should load show Source page" do
    source = latest_seeded_source
    visit source_path(source)
    expect(page).to have_xpath("//dd[contains(.,'#{source.public_id}')]")
  end

  it "should load show Name page" do
    name = latest_seeded_name
    visit name_path(name)
    expect(page).to have_content("#{name.public_id}")
  end

  it "should load show Manuscript page" do
    # randomly link 2 entries together in a MS
    entries = latest_seeded_entries
    ms = Manuscript.create!(
      entry_manuscripts_attributes: [
        { entry_id: entries[0].id, relation_type: EntryManuscript::TYPE_RELATION_IS },
        { entry_id: entries[1].id, relation_type: EntryManuscript::TYPE_RELATION_IS },
      ]
    )

    visit manuscript_path(ms)

    expect(page).to have_content(ms.public_id)
  end

  it "should add search to History" do
    login(@user, 'somethingreallylong')
    visit root_path
    find('#dismiss-welcome').click if page.has_css?('#dismiss-welcome')

    fill_in "q", with: "My Unique Search"
    click_button('search')
    expect(page).to have_selector('#documents')

    visit "/search_history"

    expect(page).to have_content("My Unique Search")
  end

end
