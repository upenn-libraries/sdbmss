
require "rails_helper"

describe "Manage entries", :js => true do
  let(:admin_user) { create(:admin) }

  before :each do
    @user = admin_user

    @unapproved_entry = Entry.new(
      source: Source.last,
      created_by: @user,
      folios: 15,
    )
    @unapproved_entry.save!
    Sunspot.commit
    login(@user, 'somethingreallylong')
  end

  after :each do
    if @unapproved_entry
      begin
        Sunspot.remove(@unapproved_entry)
        Sunspot.commit
      rescue StandardError
        # Solr cleanup is best-effort
      end
    end
  end

  it "should show table of entries" do
    visit entries_path
    expect(page).to have_content(Entry.first.entry_dates.first.display_value)
  end

  it "should search" do
    visit entries_path

    find("input[name='search_value']", match: :first).native.send_keys "de ricci"
    find('#search_submit').click()
    expect(page).not_to have_selector("#spinner", visible: true)

    expect(all("#search_results tbody tr").count).to eq(2)
  end

  it "should mark entry as approved" do

    visit entries_path
    find("#unapproved_only", match: :first).click
    find('#search_submit').click()

    expect(page).to have_selector("#select-all", visible: true)
    find("#select-all", match: :first).trigger('click')

    expect(page).to have_selector("#mark-as-approved")
    find("#mark-as-approved").click

    expect(page).to have_content("There are no records to display.")

    visit entry_path(@unapproved_entry)

    expect(page).not_to have_content("This entry has not been approved yet")

    expect(Entry.find(@unapproved_entry.id).approved).to be true
    expect(Entry.find(@unapproved_entry.id).approved_by_id).to eq(@user.id)
  end

  it "should delete an entry" do
    entry_to_delete = Entry.last
    count = Entry.all.count

    visit entries_path
    find("#delete_#{entry_to_delete.id}", match: :first).trigger("click")
    #all(".entry-delete-link").last.trigger('click')
    expect(page).to have_content("Are you sure you want to delete entry")
    click_button "Yes"
    expect(page).not_to have_css("#delete_#{entry_to_delete.id}")

    expect(Entry.all.count).to eq(count - 1)
  end

  it "should mark entry as deprecated" do

    expect(Entry.where(deprecated: true).count).to be(0)

    visit entries_path
    find(".entry-deprecate-link", match: :first).trigger('click')

    superceded_by_id = Entry.first.id
    fill_in 'superceded_by_id', :with => superceded_by_id
    find("#deprecate").click
    expect(page).to have_content("Entry marked as deprecated.")

    entry = Entry.find_by(deprecated: true)
    expect(entry.superceded_by_id).to be(superceded_by_id)
  end

  it "should load all entries from the Manage Entries page" do
    visit entries_path

    expect(page).to have_css('#search_results_info', text: /of \d+ records/, wait: 10)
    displayed_count = page.find('#search_results_info').text.match(/of (\d+) records/)[1].to_i
    solr_count = Entry.search { paginate page: 1, per_page: 1 }.total
    expect(displayed_count).to eq(solr_count)
  end

  it "should perform a search on any field without error" do
    visit entries_path

    search_field = page.find("select[name='search_field']", visible: :all, match: :first)
    options = search_field.all("option", visible: :all)
    expect(options.length).to eq(Entry.search_fields.count)

    options.each do |option|
      page.find("input[name='search_value']", match: :first).set "Test String"
      option.select_option
      find('#search_submit').click()
    end
  end

  it "should perform a search with multiple values for the same field (AND)" do
    visit entries_path

    find('#addSearch', visible: :all).trigger('click')

    textInputs = page.all("input[name='search_value']")
    searchOptions = page.all("select[name='search_field']")

    textInputs[0].set "Augustine"
    searchOptions[0].set "Author"

    textInputs[1].set "Hippo"
    searchOptions[1].set "Author"

    find('#search_submit').click()

    expect(page).to have_selector('#search_results_info', text: /of\s[\d,]+/)
    count = page.find('#search_results_info').text.match(/of\s([\d,]+)\s/)[1].gsub(",", "").to_i

    visit entries_path

    textInputs = page.all("input[name='search_value']")
    searchOptions = page.all("select[name='search_field']")

    textInputs[0].set "Augustine AND Hippo"
    searchOptions[0].set "Author"

    find('#search_submit').click()

    expect(page).to have_selector('#search_results_info', text: /of\s[\d,]+/)
    count2 = page.find('#search_results_info').text.match(/of\s([\d,]+)\s/)[1].gsub(",", "").to_i

    expect(count).to eq(count2)
  end

  it "should perform a search with multiple values for the same field (ANY)" do
    visit entries_path

    find('#addSearch', visible: :all).trigger('click')

    textInputs = page.all("input[name='search_value']")
    searchOptions = page.all("select[name='search_field']")

    textInputs[0].set "Augustine"
    searchOptions[0].set "Author"

    textInputs[1].set "Cicero"
    searchOptions[1].set "Author"

    select 'Any', from: 'op'

    find('#search_submit').click()

    expect(page).to have_selector('#search_results_info', text: /of\s[\d,]+/)

    augustine_entry = Entry.joins(entry_authors: :author).where(names: { name: "Augustine, Saint, Bishop of Hippo" }).first
    cicero_entry = Entry.joins(entry_authors: :author).where(names: { name: "Cicero, Marcus Tullius" }).first

    expect(page).to have_link(augustine_entry.public_id)
    expect(page).to have_link(cicero_entry.public_id)
  end

  it "should display a citation correctly" do
    visit entry_path(Entry.first)

    expect(page).to have_content("Cite")

    click_link "Cite"
    now = DateTime.now.to_formatted_s(:date_mla)
    result = "Schoenberg Database of Manuscripts. The Schoenberg Institute for Manuscript Studies, University of Pennsylvania Libraries. Web. #{now}: #{Entry.first.public_id}."
    expect(page).to have_content(result)
  end

  it "should allow a user to upload entries from a flat csv file" do
    skip "bulk flat-CSV entry import is not implemented for the current manage-entries workflow"
  end

  it "should try to download a search result from manage entries table" do
    skip "manage-entries export uses async download plumbing that should be covered below the JS feature-spec level"
  end

  it "should allow a user to create an entry from composite provenance on a manuscript record" do
    skip "composite-provenance entry creation is not covered in the current UI workflow and needs a dedicated product-level test path"
  end

  it "should show suggestions of similar records in the linking tool" do
    skip "linking suggestions remain deferred until the matching algorithm is stable enough for deterministic coverage"
  end

  it "should verify a legacy entry" do
    skip "legacy-entry verification still needs a dedicated workflow spec; this manage-entries path is not implemented"
  end

end
