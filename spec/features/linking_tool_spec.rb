
require 'json'
require "rails_helper"

# There's JS on most of these pages. Not all features use JS, but
# there's no good reason NOT to use the js driver, so we do.
describe "Linking Tool", :js => true do

  before :all do
    # since we already have a set of reference data, we use that here
    # instead of creating another set of test data. The consequence is
    # that these tests don't exercise everything as thoroughly as they
    # should, but they're probably good enough.
#    SDBMSS::ReferenceData.create_all

    SDBMSS::Util.wait_for_solr_to_be_current
  end

  before :all do
    @user = User.where(role: "admin").first
=begin    
    User.where(username: 'testuser').delete_all
    @user = User.create!(
      email: 'testuser@test.com',
      username: 'testuser',
      password: 'somethingunguessable'
    )
=end    
  end

  before :each do
    login(@user, 'somethingunguessable')
  end

  after :each do
    page.reset!
  end

  it "should load" do
    entry = Entry.last(2)[0]

    visit linking_tool_by_entry_path(id: entry.id)
    expect(page).to have_content("Click here for instructions")
    expect(page).to have_content(Entry.last.source.title)
    expect(all("#workspace tbody tr").count).to eq(1)

    expect(find_by_id("search_results").find("tbody").all("tr").length).to be > 0
  end

  it "should show potential matches" do
    skip "disabled until algorithm is improved"
    entry = Entry.last
    visit linking_tool_by_entry_path id: entry.id
    find_by_id("show-matches").trigger('click');
    #click_button('Suggest links')
    sleep 2

    expect(find(".modal-title", visible: true).text.include?("No matches found")).to be_truthy
  end

  # NOTE: tests here rely on data created by previous tests

  it "should create a new Manuscript out of ONE entry" do
    count = Manuscript.count

    entry = Entry.first(2)[1]
    visit linking_tool_by_entry_path id: entry.id
    expect(page).to have_content("Click here for instructions")
    expect(page).to have_content(Entry.last.source.title)
    find('#persist-entries-manuscript-link').click

    expect(page).to have_content("Manage Manuscripts")    
    #expect(find(".modal-title", visible: true).text.include?("Success")).to be_truthy

    expect(Manuscript.count).to eq(count + 1)

    entries = Manuscript.last.entries
    entry_ids = entries.map(&:id)
    expect(entry_ids.count).to eq(1)
    expect(entry_ids.include?(entry.id)).to be_truthy
  end

  it "should create a new Manuscript out of two entries" do
    count = Manuscript.count

    entry = Entry.last(3)[0]
    visit linking_tool_by_entry_path id: entry.id

    second_entry_id = first(".add-entry-link", visible: true)["data-entry-id".to_sym].to_i
    first(".add-entry-link", visible: true).trigger('click')

    find('#persist-entries-manuscript-link').click

    expect(page).to have_content("Manage Manuscripts")    
    #expect(find(".modal-title", visible: true).text.include?("Success")).to be_truthy

    expect(Manuscript.count).to eq(count + 1)

    entries = Manuscript.last.entries
    entry_ids = entries.map(&:id)
    expect(entry_ids.count).to eq(2)
    expect(entry_ids.include?(entry.id)).to be_truthy
    expect(entry_ids.include?(second_entry_id)).to be_truthy
  end

  it "should show an EntryManuscript for the last created link" do
    visit entry_manuscripts_path

    expect(page).to have_content(Manuscript.last.public_id)
    expect(page).to have_content(Entry.last(3)[0].public_id)

    expect(page).to have_content(EntryManuscript.last.id)
  end

  it "should link an Entry to an existing Manuscript" do
    entry = Entry.find(3)
    visit linking_tool_by_entry_path id: entry.id

    expect(page).to have_content("Link to SDBM")
    # use manuscript created in previous test
    first(".link-to-manuscript-link", visible: true).trigger('click')

    click_button "Yes"

    expect(page).not_to have_content("Manage Entries")
    expect(page).to have_content("Manage Manuscripts")    
#    expect(find(".modal-title", visible: true).text.include?("Successfully Linked")).to be_truthy

    entry.reload

    expect(entry.manuscripts.count).to eq(1)
  end

  it "should add an entry to an existing Manuscript" do
    # use manuscript created in previous test
    manuscript = Manuscript.last
    count = manuscript.entries.count

    visit linking_tool_by_manuscript_path id: manuscript.id
    entry_id = first(".add-entry-link", visible: true)["data-entry-id".to_sym].to_i
    first(".add-entry-link", visible: true).trigger('click')

    find("#persist-entries-manuscript-link").trigger('click')

    expect(page).not_to have_content("Add SDBM_#{entry_id}")    
#    expect(find(".modal-title", visible: true).text.include?("Success")).to be_truthy

    entries = Manuscript.last.entries
    entry_ids = entries.map(&:id)
    expect(entry_ids.count).to eq(count + 1)
    expect(entry_ids.include?(entry_id)).to be_truthy
  end

  it "should change an Entry's relation to a Manuscript to 'possible'" do
    manuscript = Manuscript.last
    visit linking_tool_by_manuscript_path id: manuscript.id

    entry = manuscript.entries.first
    entry_id = entry.id

    first("input[name='entry_id_#{entry.id}'][value='possible']").trigger('click')

    find("#persist-entries-manuscript-link").trigger('click')

    sleep 2
    expect(page).to have_content("SDBM_MS")

    em = manuscript.entry_manuscripts.select { |em| em.entry_id == entry_id }.first
    expect(em.relation_type).to eq('possible')
  end

  it "should remove an entry from an existing Manuscript" do
    manuscript = Manuscript.last
    visit linking_tool_by_manuscript_path id: manuscript.id

    entry = manuscript.entries.first
    entry_id = entry.id

    first("input[name='entry_id_#{entry.id}'][value='unlink']").trigger('click')

    find("#persist-entries-manuscript-link").trigger('click')

    expect(page).to have_content("Add SDBM_#{entry_id}")    
#    expect(find(".modal-title", visible: true).text.include?("Success")).to be_truthy

    SDBMSS::Util.wait_for_solr_to_be_current
    manuscript.reload

    entry_ids = manuscript.entries.map(&:id)
    expect(entry_ids.include?(entry_id)).to eq(false)
  end

  it "should remove the last entry from an existing Manuscript" do
    manuscript = Manuscript.last
    visit linking_tool_by_manuscript_path id: manuscript.id

    # remove all except the last entry

    entryCount = manuscript.entries.length
    (entryCount - 1).times do |i|
      entry_id = manuscript.entries[i].id
      first("input[name='entry_id_#{entry_id}'][value='unlink']").trigger('click')
    end
    
    find_by_id("persist-entries-manuscript-link").trigger("click")
    #expect(find("div#modal.modal.fade.in")).to have_content("hasdfa")
    #click_button "Save changes"
    #expect(page).to have_content("Success")
    expect(page).to have_content("SDBM_MS")    
#    expect(find(".modal-title", visible: true).text.include?("Success")).to be_truthy
    manuscript.reload

    SDBMSS::Util.wait_for_solr_to_be_current
    # remove the last entry

    expect(manuscript.entries.count).to eq(1)
    entry = manuscript.entries.first
    entry_id = entry.id

    first("input[name='entry_id_#{entry_id}'][value='unlink']").trigger('click')
    find_by_id("persist-entries-manuscript-link").trigger("click")
    #click_button "Save changes"
    expect(page).to have_content("SDBM_MS")    
#    expect(find(".modal-title", visible: true).text.include?("Success")).to be_truthy

    manuscript.reload

#    expect(manuscript.entries.length).to eq(0)
  end

  it "should warn the user that there are unsaved changes before leaving page" do
    expect(pending("test not created yet")).to fail
  end

  it "should show error message when overwriting changes" do

    last_two_entries = Entry.last(2)

    manuscript = Manuscript.new
    manuscript.save!
    manuscript_id = manuscript.id

    manuscript.update_attributes!(
      entry_manuscripts_attributes: [
        {
          entry_id: last_two_entries[0].id,
          relation_type: EntryManuscript::TYPE_RELATION_IS
        },
        {
          entry_id: last_two_entries[1].id,
          relation_type: EntryManuscript::TYPE_RELATION_IS
        }
      ]
    )

    visit linking_tool_by_manuscript_path id: manuscript.id

    # MUST sleep so that updating EntryManuscript changes updated_at
    sleep(2)

    # it's crucial that we load a fresh object
    manuscript = Manuscript.find(manuscript_id)
    em = manuscript.entry_manuscripts[0]
    em.relation_type = EntryManuscript::TYPE_RELATION_PARTIAL
    em.save!

    # there are actually TWO inputs that match here, because of some
    # HTML craziness that happens with th datatable's fixed
    # columns. whatever. just click one.
    all("input[name='entry_id_#{last_two_entries[0].id}'][value='possible']")[1].trigger('click')

    find("#persist-entries-manuscript-link").trigger('click')

    expect(find(".modal-body", visible: true).text.include?("Another change was made to the record while you were working")).to be_truthy
  end

end
