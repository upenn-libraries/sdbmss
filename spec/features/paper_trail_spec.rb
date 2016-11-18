# paper trail spec

require "rails_helper"

describe "Paper trail", :js => true do

  # Fill an autocomplete field using value in :with option. If a
  # block is given, yields to it to allow for selection.
  def fill_autocomplete(field, options = {})
    # adapted from http://ruby-journal.com/how-to-do-jqueryui-autocomplete-with-capybara-2/

    # This version here works with the autocomplete in jQuery UI
    # 1.11.2. WARNING: This code is very fragile! We have to simulate
    # interaction with DOM EXACTLY.

    page.execute_script %Q{ $('##{field}').trigger('focus') }

    # clear the field first
    fill_in field, :with => ""

    # capybara's fill_in doesn't trigger the DOM events autocomplete
    # listens for; use send_keys instead
    find_by_id(field).native.send_keys(options[:with])

    # wait for an autocomplete UL element to appear
    find('ul.ui-autocomplete', visible: true)

    # yield to block to handle the selection
    if block_given?
      yield field, options
    end
  end

  # Specialized case of #fill_autocomplete for inputs that show a
  # modal popup for creating new entities. This selects the value
  # given in :with option if it's available, otherwise creates it in
  # the modal popup that should appear.
  def fill_autocomplete_select_or_create_entity(field, options = {})
    value = options[:with]

    fill_autocomplete(field, options) do
      found_value = nil
      all("ul.ui-autocomplete li.ui-menu-item", visible: true).each do |li|
        if li.text == value || li.text == value + " (unreviewed)"
          found_value = li.text
        end
      end
      if found_value.present?
        value_escaped = found_value.gsub("'", "\\\\'")
        selector = %Q{ul.ui-autocomplete:visible li.ui-menu-item:contains("#{value_escaped}")}
      else
        # select the 1st option, which should pop up the modal to create an entity
        selector = %Q{ul.ui-autocomplete:visible li.ui-menu-item:eq(0)}
      end
      page.execute_script %Q{ $('#{selector}').click() }

      if !found_value.present?
        expect(find(".modal-title", visible: true).text.include?("Create")).to be_truthy
        click_button('Create')
        sleep(0.75)
        # this next line should be used instead of a sleep, but doesn't work for some reason
        # expect(page).to have_no_selector(".modal-title", visible: true)
      end
    end
    #page.save_screenshot("screenshot_#{field}.png")
  end

  # clicks the certainty flag icon to toggle it to its next state.
  # Since clicking also brings up the mouseover tooltip, which
  # overlaps over DOM elements and can interfere with subsequent
  # interactions with the page, we have this abstraction to hover out
  # of it afterwards.
  def click_certainty_flag(field)
    find_by_id(field).click
    # hover over something else--the navbar element here is just
    # arbitrary
    first(".navbar-brand").hover
    sleep(2)
  end


  before :all do
    User.where(username: 'testuser').delete_all
    @user = User.create!(
      email: 'testuser@test.com',
      username: 'testuser',
      password: 'somethingunguessable'
    )

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
      visit new_user_session_path
      fill_in 'user_login', :with => @user.username
      fill_in 'user_password', :with => 'somethingunguessable'
      click_button 'Log in'
      expect(page).to have_content 'Signed in successfully'
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
        sleep(1.5)
        expect(find(".modal-title", visible: true).text.include?("Successfully saved")).to be_truthy

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

        find('#delete_title_0').click
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