
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
    SDBMSS::ReferenceData.create_all

    SDBMSS::Util.wait_for_solr_to_be_current
  end

  before :all do
    User.where(username: 'testuser').delete_all
    @user = User.create!(
      email: 'testuser@test.com',
      username: 'testuser',
      password: 'somethingunguessable'
    )
  end

  before :each do
    visit new_user_session_path
    fill_in 'user_login', :with => @user.username
    fill_in 'user_password', :with => 'somethingunguessable'
    click_button 'Log in'
    expect(page).to have_content 'Signed in successfully'
  end

  after :each do
    page.reset!
  end

  it "should load" do
    entry = Entry.last

    visit linking_tool_by_entry_path id: entry.id
    expect(page).to have_content("Entry Queue for creating Links")
    expect(page).to have_content("Search for possible links")

    expect(find_by_id("workspace").find("tbody").all("tr").length).to eq(1)

    expect(find_by_id("search_results").find("tbody").all("tr").length).to be > 0
  end

  it "should show potential matches" do
    entry = Entry.last
    visit linking_tool_by_entry_path id: entry.id
    click_button('Show potential links')
    sleep 2

    expect(find(".modal-title", visible: true).text.include?("No matches found")).to be_truthy
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

    sleep(2)

    # it's crucial that we load a fresh object
    manuscript = Manuscript.find(manuscript_id)
    em = manuscript.entry_manuscripts[0]
    em.relation_type = EntryManuscript::TYPE_RELATION_PARTIAL
    em.save!

    # there are actually TWO inputs that match here, because of some
    # HTML craziness that happens with th datatable's fixed
    # columns. whatever. just click one.
    all("input[name='entry_id_#{last_two_entries[0].id}'][value='possible']")[1].click

    click_button "Save changes"

    sleep(1)

    expect(find(".modal-body", visible: true).text.include?("Another change was made to the record while you were working")).to be_truthy
  end

end
