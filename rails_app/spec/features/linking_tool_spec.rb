
require 'json'
require "rails_helper"

# There's JS on most of these pages. Not all features use JS, but
# there's no good reason NOT to use the js driver, so we do.
describe "Linking Tool", :js => true do
  let_it_be(:admin_user) { create(:admin) }
  let(:admin_password) { 'somethingreallylong' }

  def click_add_entry_link(entry_id)
    page.find(
      ".add-entry-link[data-entry-id='#{entry_id}']",
      visible: true,
      match: :first
    ).trigger('click')
  end

  def choose_workspace_relation(entry_id, relation_type)
    inputs = all("input[name='entry_id_#{entry_id}'][value='#{relation_type}']", visible: true)
    (inputs[1] || inputs.first).trigger('click')
  end

  def create_linking_entry(source:, title:, catalog_or_lot_number:)
    create(
      :edit_entry_with_titles,
      source: source,
      created_by: admin_user,
      titles: [title],
      include_author: false,
      catalog_or_lot_number: catalog_or_lot_number,
    )
  end

  def create_linked_manuscript(*entries)
    manuscript = create(:manuscript, created_by: admin_user, updated_by: admin_user)
    entries.each do |entry|
      create(
        :entry_manuscript,
        entry: entry,
        manuscript: manuscript,
        relation_type: EntryManuscript::TYPE_RELATION_IS,
        created_by: admin_user,
        updated_by: admin_user,
      )
    end
    manuscript
  end

  def index_records(*records)
    records.flatten.each { |record| Sunspot.index(record) }
    Sunspot.commit
    SDBMSS::Util.wait_for_solr_to_be_current
  end

  def persist_linking_changes
    find("#persist-entries-manuscript-link").trigger('click')
    expect(page).to have_content("SDBM_MS")
  end

  def build_linking_fixture(count: 3, source_title: "Linking Tool Source", shared_title: "Linking Tool Shared Title")
    source = create(:edit_test_source, created_by: admin_user, title: source_title)
    entries = count.times.map do |index|
      create_linking_entry(
        source: source,
        title: shared_title,
        catalog_or_lot_number: "LT-#{index + 1}"
      )
    end
    index_records(source, entries)
    [source, entries]
  end

  before :each do
    login(admin_user, admin_password)
  end

  after :each do
    page.reset!
  end

  it "should load", :flaky do
    source, entries = build_linking_fixture(count: 2, source_title: "Linking Tool Load Source")
    entry = entries.first

    visit linking_tool_by_entry_path(id: entry.id)
    expect(page).to have_content("Click here for instructions")
    expect(page).to have_content(source.title)
    expect(all("#workspace tbody tr").count).to eq(1)

    expect(find_by_id("search_results").find("tbody").all("tr").length).to be > 0
  end

  it "should show potential matches" do
    skip "disabled until algorithm is improved"
    _source, entries = build_linking_fixture(count: 2, source_title: "Linking Tool Matches Source")
    entry = entries.first
    visit linking_tool_by_entry_path id: entry.id
    find_by_id("show-matches").trigger('click');
    #click_button('Suggest links')
    sleep 2

    expect(find(".modal-title", visible: true).text.include?("No matches found")).to be_truthy
  end

  it "should create a new Manuscript out of ONE entry" do
    source, entries = build_linking_fixture(count: 2, source_title: "Linking Tool One Entry Source")
    entry = entries.second
    visit linking_tool_by_entry_path id: entry.id
    expect(page).to have_content("Click here for instructions")
    expect(page).to have_content(source.title)
    persist_linking_changes

    expect(page).to have_content("Manage Manuscripts")    
    #expect(find(".modal-title", visible: true).text.include?("Success")).to be_truthy

    manuscript = entry.reload.manuscripts.first
    expect(entry.manuscripts.count).to eq(1)
    entry_ids = manuscript.entries.map(&:id)
    expect(entry_ids.count).to eq(1)
    expect(entry_ids.include?(entry.id)).to be_truthy
  end

  it "should create a new Manuscript out of two entries" do
    _source, entries = build_linking_fixture(count: 3, source_title: "Linking Tool Two Entry Source")
    entry = entries.first
    other_entry = entries.second
    visit linking_tool_by_entry_path id: entry.id

    click_add_entry_link(other_entry.id)

    persist_linking_changes

    expect(page).to have_content("Manage Manuscripts")    
    #expect(find(".modal-title", visible: true).text.include?("Success")).to be_truthy

    manuscript = entry.reload.manuscripts.first
    other_manuscript = other_entry.reload.manuscripts.first
    expect(entry.manuscripts.count).to eq(1)
    expect(other_entry.manuscripts.count).to eq(1)
    expect(other_manuscript.id).to eq(manuscript.id)
    entry_ids = manuscript.entries.map(&:id)
    expect(entry_ids.count).to eq(2)
    expect(entry_ids.include?(entry.id)).to be_truthy
    expect(entry_ids.include?(other_entry.id)).to be_truthy
  end

  it "should show an EntryManuscript for the last created link" do
    _source, entries = build_linking_fixture(count: 1, source_title: "Linking Tool EntryManuscript Source")
    entry = entries.first
    manuscript = create(:manuscript, created_by: admin_user, updated_by: admin_user)
    em = create(:entry_manuscript, entry: entry, manuscript: manuscript, relation_type: 'is', created_by: admin_user, updated_by: admin_user)
    index_records(em, manuscript)

    visit entry_manuscripts_path

    expect(page).to have_content(manuscript.public_id)
    expect(page).to have_content(entry.public_id)
    expect(page).to have_content(em.id.to_s)
  end

  it "should link an Entry to an existing Manuscript" do
    source, entries = build_linking_fixture(count: 2, source_title: "Linking Tool Existing Manuscript Source")
    entry = entries.first
    manuscript = create_linked_manuscript(entries.second)
    index_records(source, entries, manuscript, manuscript.entry_manuscripts)
    visit linking_tool_by_entry_path id: entry.id

    expect(page).to have_content("Link to SDBM")
    page.find(
      ".link-to-manuscript-link[data-manuscript-id='#{manuscript.id}']",
      visible: true,
      match: :first
    ).trigger('click')

    click_button "Yes"

    expect(page).not_to have_content("Manage Entries")
    expect(page).to have_content("Manage Manuscripts")    
#    expect(find(".modal-title", visible: true).text.include?("Successfully Linked")).to be_truthy

    entry.reload

    expect(entry.manuscripts.count).to eq(1)
  end

  it "should add an entry to an existing Manuscript" do
    source, entries = build_linking_fixture(count: 2, source_title: "Linking Tool Add Entry Source")
    manuscript = create_linked_manuscript(entries.first)
    candidate_entry = entries.second
    index_records(source, entries, manuscript, manuscript.entry_manuscripts)
    count = manuscript.entries.count

    visit linking_tool_by_manuscript_path id: manuscript.id
    click_add_entry_link(candidate_entry.id)

    persist_linking_changes

    expect(page).not_to have_content("Add SDBM_#{candidate_entry.id}")    
#    expect(find(".modal-title", visible: true).text.include?("Success")).to be_truthy

    entry_ids = manuscript.reload.entries.map(&:id)
    expect(entry_ids.count).to eq(count + 1)
    expect(entry_ids.include?(candidate_entry.id)).to be_truthy
  end

  it "should change an Entry's relation to a Manuscript to 'possible'" do
    _source, entries = build_linking_fixture(count: 1, source_title: "Linking Tool Possible Source")
    manuscript = create_linked_manuscript(entries.first)
    index_records(manuscript, manuscript.entry_manuscripts)
    visit linking_tool_by_manuscript_path id: manuscript.id

    entry = manuscript.entries.first
    entry_id = entry.id

    choose_workspace_relation(entry.id, 'possible')

    persist_linking_changes

    em = manuscript.reload.entry_manuscripts.find_by(entry_id: entry_id)
    expect(em.relation_type).to eq('possible')
  end

  it "should remove an entry from an existing Manuscript" do
    _source, entries = build_linking_fixture(count: 1, source_title: "Linking Tool Remove Source")
    manuscript = create_linked_manuscript(entries.first)
    index_records(manuscript, manuscript.entry_manuscripts)
    visit linking_tool_by_manuscript_path id: manuscript.id

    entry = manuscript.entries.first
    entry_id = entry.id

    find("input[name='entry_id_#{entry.id}'][value='unlink']", match: :first).trigger('click')

    persist_linking_changes

    manuscript.reload

    entry_ids = manuscript.entries.map(&:id)
    expect(entry_ids.include?(entry_id)).to eq(false)

    index_records(entry.reload, manuscript)
    visit linking_tool_by_manuscript_path id: manuscript.id

    expect(page).to have_content("Add SDBM_#{entry_id}")
  end

  it "should remove the last entry from an existing Manuscript" do
    _source, entries = build_linking_fixture(count: 2, source_title: "Linking Tool Remove Last Source")
    manuscript = create_linked_manuscript(entries.first, entries.second)
    index_records(manuscript, manuscript.entry_manuscripts)
    visit linking_tool_by_manuscript_path id: manuscript.id

    # remove all except the last entry

    entryCount = manuscript.entries.length
    (entryCount - 1).times do |i|
      entry_id = manuscript.entries[i].id
      find("input[name='entry_id_#{entry_id}'][value='unlink']", match: :first).trigger('click')
    end
    
    persist_linking_changes
    #expect(find("div#modal.modal.fade.in")).to have_content("hasdfa")
    #click_button "Save changes"
    #expect(page).to have_content("Success")
    expect(page).to have_content("SDBM_MS")    
#    expect(find(".modal-title", visible: true).text.include?("Success")).to be_truthy
    manuscript.reload

    # remove the last entry

    expect(manuscript.entries.count).to eq(1)
    entry = manuscript.entries.first
    entry_id = entry.id

    find("input[name='entry_id_#{entry_id}'][value='unlink']", match: :first).trigger('click')
    persist_linking_changes
    #click_button "Save changes"
    expect(page).to have_content("SDBM_MS")    
#    expect(find(".modal-title", visible: true).text.include?("Success")).to be_truthy

    manuscript.reload

#    expect(manuscript.entries.length).to eq(0)
  end

  it "should warn the user that there are unsaved changes before leaving page" do
    skip "unsaved-change navigation warning still needs a stable browser-level assertion strategy for this Angular workflow"
  end

  it "should show error message when overwriting changes" do

    _source, last_two_entries = build_linking_fixture(count: 2, source_title: "Linking Tool Overwrite Source")
    manuscript = create_linked_manuscript(*last_two_entries)
    manuscript_id = manuscript.id
    index_records(manuscript, manuscript.entry_manuscripts)

    visit linking_tool_by_manuscript_path id: manuscript.id

    expect(page).to have_content(last_two_entries.first.public_id)

    # it's crucial that we load a fresh object.
    # Use update_columns with an explicit future timestamp so that
    # cumulative_updated_at (second-precision .to_i) is guaranteed to
    # differ from the value the browser captured on page load.
    manuscript = Manuscript.find(manuscript_id)
    em = manuscript.entry_manuscripts[0]
    em.update_columns(
      relation_type: EntryManuscript::TYPE_RELATION_PARTIAL,
      updated_at: 1.minute.from_now
    )

    # Datatable/fixed-column rendering can duplicate these inputs; select any
    # visible matching input rather than assuming a fixed index.
    possible_inputs = all("input[name='entry_id_#{last_two_entries[0].id}'][value='possible']", minimum: 1)
    possible_input = possible_inputs.find(&:visible?) || possible_inputs.first
    possible_input.trigger('click')

    persist_linking_changes

    expect(page).to have_content("Another change was made to the record while you were working")
  end

end
