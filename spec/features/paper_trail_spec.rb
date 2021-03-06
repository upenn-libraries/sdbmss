# paper trail spec

require "rails_helper"

describe "Paper trail", :js => true do

  # clicks the certainty flag icon to toggle it to its next state.
  # Since clicking also brings up the mouseover tooltip, which
  # overlaps over DOM elements and can interfere with subsequent
  # interactions with the page, we have this abstraction to hover out
  # of it afterwards.
  def click_certainty_flag(field)
    find_by_id(field).click
    # hover over something else--the navbar element here is just
    # arbitrary
    #first('#header-navbar').hover
    #sleep(2)
  end


  before :all do
    @user = User.where(role: "admin").first

    @source = Source.find_or_create_by(
      title: "A Sample Test Source With a Highly Unique Name",
      date: "2013-11-12",
      source_type: SourceType.auction_catalog,
    )
    source_agent = SourceAgent.create!(
      source: @source,
      role: SourceAgent::ROLE_SELLING_AGENT,
      agent: Name.find_or_create_agent("Sotheby's")
    )
  end

  context "when user is logged in" do

    before :each do
      login(@user, 'somethingunguessable')
    end

    after :each do
      page.reset!
    end

    require "lib/data_entry_helpers"
    include DataEntryHelpers    

    describe '(for simple changes)' do

      it 'should load the history page successfully' do
        create_entry

        e = Entry.last

        visit history_entry_path (e)

        expect(page).to have_content("History of changes to #{e.public_id}")
      end

      it "should register changes in the entry basic fields" do
        e = Entry.last

        visit edit_entry_path (e)

        fill_in 'folios', with: 10000
        first(".save-button").click

        expect(page).to have_content("Warning: This entry has not been approved yet.")
        expect(page).to have_content(e.public_id)

        visit history_entry_path (e)

        expect(page).to have_content('Folios')
        expect(page).to have_content('10000')
        expect(page).to have_content('123')
      end

      it "should present the option to revert simple changes" do
        e = Entry.last

        visit history_entry_path (e)

        f = first('.active', text: 'Folios')
        f = f.find('.btn-undo').click()
        
        expect(page).to have_content('Revert to Old Version')
        expect(page).to have_content('10000')
        expect(page).to have_content('123')
        expect(page).to have_content(e.public_id)
      end

      it "should successfully restore the previous version" do
        e = Entry.last

        visit history_entry_path (e)

        f = first('.active', text: 'Folios')
        f = f.find('.btn-undo').click()
        
        click_button('Restore')

        sleep(1.1)

        expect(page).to have_content(e.public_id)
        expect(page).to have_content(123)
        expect(page).not_to have_content(10000)
      end
    end

    describe '(for changes to associations)' do
      
      it "should show a change to an association in change history" do
        e = Entry.last

        visit edit_entry_path (e)
        fill_in 'title_0', with: 'Hiiipower'

        first('.save-button').click
        sleep(1.5)

        visit entry_path (e)

        expect(page).to have_content('Hiiipower')

        visit history_entry_path (e)
        expect(page).to have_content('Book of Hours')
        expect(page).to have_content('Hiiipower')

      end

      it "should show options to revert an 'association' change" do
        e = Entry.last

        visit history_entry_path (e)

        f = first('.active', text: 'Hiiipower')
        f = f.find('.btn-undo').click()

        expect(page).to have_content(e.public_id)
        expect(page).to have_content('Hiiipower')
        expect(page).to have_content('Book of Hours')
      end

      it "should successfully restore the previous association by overwriting the new field" do
        e = Entry.last

        old_count = e.entry_titles.count

        visit history_entry_path (e)

        f = first('.active', text: 'Hiiipower')
        f = f.find('.btn-undo').click()

        click_button('Restore')
        sleep(1.1)

        expect(page).to have_content('Book of Hours')
        expect(page).not_to have_content('Hiiipower')
        expect(old_count).to eq(e.entry_titles.count)      
      end

      it "should save a 'revert' change in the record history" do
        e = Entry.last

        visit history_entry_path (e)

        f = first('.active', text: 'Hiiipower')
        expect(f).to have_content('changed Title')
        expect(f).to have_content('Book of Hours')
      end

      it "should recreate an associated field that was deleted" do
        e = Entry.last
        old_count = e.entry_titles.count

        visit edit_entry_path (e)

        t = find('#title_0').value

        find_by_id("delete_title_0").click
        expect(page).to have_content("Are you sure you want to remove this field and its contents?")
        click_button "Yes"

        first(".save-button").click
        
        sleep(1.1)

        new_count = e.entry_titles.count
        expect(old_count).to eq(new_count + 1)

        visit history_entry_path (e)
        f = first('.active', text: 'Title')
        expect(f).to have_content('deleted Title')
        f = f.find('.btn-undo').click()

        expect(page).to have_content(t)

        click_button('Restore')

        sleep(1.1)

        expect(page).to have_content(t)
        expect(e.entry_titles.count).to eq(old_count)
        expect(e.entry_titles.count).not_to eq(new_count)
      end

      it "should remove an associated field that was created" do
        e = Entry.last
        old_count = e.entry_titles.count

        visit history_entry_path e
        
        f = first('.active', text: 'Title')
        expect(f).to have_content('added Title')
        f = f.find('.btn-undo').click()

        expect(page).to have_content('Book of Hours')
        click_button('Restore')

        sleep(1.1)

        #expect(page).not_to have_content('Book of Hours')
        expect(e.entry_titles.count).to eq(old_count - 1)
      end
      # revert successfully, add, and combine
    end

  end
end