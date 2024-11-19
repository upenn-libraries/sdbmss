require "rails_helper"

describe "Data entry", :js => true do
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
  #def click_certainty_flag(field)
  #  find_by_id(field).click
    # hover over something else--the navbar element here is just
    # arbitrary
  #  first('#header-navbar').hover
  #  sleep(2)
  #end

  before :all do
    #User.where(username: 'testuser').delete_all
    @user = User.where(role: 'admin').first
=begin
    User.create!(
      email: 'testuser@test.com',
      username: 'testuser',
      password: 'somethingunguessable'
    )
=end    

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

    it "should edit an existing Source" do
      source = Source.create!(
        date: "20141215",
        title: "my existing source",
        source_type: SourceType.auction_catalog,
        created_by: @user,
      )

      visit edit_source_path :id => source.id

      expect(page).to have_content("Edit " + source.public_id)

      expect(page).to have_select('source_type', disabled: true, selected: 'Auction/Dealer Catalog')
      expect(page).to have_field('source_date', with: '2014-12-15')
      expect(page).to have_field('title', with: 'my existing source')

      click_button('Save')

#      expect(page).to have_content(entry.public_id)

      source = Source.last
      expect(source.source_type).to eq(SourceType.auction_catalog)
      expect(source.date).to eq('20141215')
      expect(source.title).to eq('my existing source')
    end


    it "should show creator on Edit page" do
      create_entry

      entry = Entry.last

      visit edit_entry_path :id => entry.id

      expect(page).to have_content "About This Entry Record"
      expect(page).to have_content "by #{entry.created_by.username}"
    end

    it "should preserve entry on Edit page when saving without making any changes" do
      #count = Entry.count

      #create_entry

      #expect(Entry.count).to eq(count + 1)

      entry = Entry.last

      visit edit_entry_path :id => entry.id

      first(".save-button").click

      expect(page).to have_content(entry.public_id)

      verify_entry(entry)
    end

    it "should create history when updating an Entry" do
      skip "(Test is out of date with new change history implementation" do
      end
      #count = Entry.count

      #create_entry

      #expect(Entry.count).to eq(count + 1)

      entry = Entry.last

      old_title = entry.entry_titles.first.title

      visit edit_entry_path :id => entry.id

      fill_in 'title_0', with: 'Changed Book'

      first(".save-button").click

      expect(page).to have_content(entry.public_id)

      entry.reload

      visit history_entry_path :id => entry.id

      # should display in 3rd row
      expect(all(:xpath, "//tr")[2].all(:xpath, ".//td")[2].text).to eq("changed Title")
      expect(all(:xpath, "//tr")[2].all(:xpath, ".//td")[3].text).to eq("Title: from #{old_title} to Changed Book")
    end

    it "should remove a title on Edit page" do
      #count = Entry.count

      #create_entry

      #expect(Entry.count).to eq(count + 1)

      entry = Entry.last

      visit edit_entry_path :id => entry.id

      # mock out the confirm dialogue
      page.evaluate_script('window.confirm = function() { return true; }')

      find_by_id("delete_title_0").click
      expect(page).to have_content("Are you sure you want to remove this field and its contents?")
      click_button "Yes"

      first(".save-button").click

      expect(page).to have_content("Warning: This entry has not been approved yet.")
      expect(page).to have_content(entry.public_id)

      entry.reload

      expect(entry.entry_titles.count).to eq(1)
      expect(entry.entry_titles.first.title).to eq("Bible")

    end

    it "should clear out a title on Edit Page" do
      #count = Entry.count

      #create_entry

      #expect(Entry.count).to eq(count + 1)

      entry = Entry.last

      visit edit_entry_path :id => entry.id

      # clear out the title field; this should result in deletion of
      # underlying entry_title record
      fill_in 'title_0', with: ''

      first(".save-button").click

      expect(page).to have_content("Warning: This entry has not been approved yet.")
      expect(page).to have_content(entry.public_id)

      entry.reload

      expect(entry.entry_titles.count).to eq(0)
      #expect(entry.entry_titles.first.title).to eq("Bible")
    end

    it "should clear out a Name Authority (autocomplete) field" do
      #count = Entry.count

      #create_entry

      #expect(Entry.count).to eq(count + 1)

      entry = Entry.last

      visit edit_entry_path :id => entry.id

      fill_in 'author_observed_name_0', with: "Joe"
      #fill_in 'author_0', with: '     '
      #fill_autocomplete('author_0', with: '     ')

      expect(page).to have_content('Schmoe, Joe')
      find_by_id('remove_author_name_authority_0').click
      expect(page).not_to have_content('Schmoe, Joe')
      #expect(find_field('author_0').value).to eq('     ')

      first(".save-button").click

      expect(page).to have_content(entry.public_id)

      entry.reload

      entry = Entry.last

      expect(page).to have_content("Warning: This entry has not been approved yet.")
      expect(entry.entry_authors.count).to eq(1)
      expect(entry.entry_authors.first.author_id).to eq(nil)
    end

    it "should warn when editing Entry to have same catalog number as existing Entry" do
      #create_entry

      visit new_entry_path :source_id => @source.id

      # make a new entry w/ same Source but diff catalog number
      fill_in 'cat_lot_no', with: "124"
      first(".save-button").click

      expect(page).to have_content("Warning: This entry has not been approved yet.")
      expect(page).to have_content(Entry.last.public_id)

      visit edit_entry_path :id => Entry.last.id
      fill_in 'cat_lot_no', with: "123"
      find_by_id('add_title').click
      find_by_id('title_0').trigger('focus')

      expect(page).to have_content "Warning! An entry with that catalog number may already exist"

      # change it back to a new number so msg goes away
      fill_in 'cat_lot_no', with: "124"
      find_by_id('add_title').click
      find_by_id('title_0').trigger('focus')

      expect(page).not_to have_content "Warning! An entry with that catalog number may already exist"
    end

    it "should disallow saving on Edit Page when another change was made" do
      #create_entry

      entry = Entry.last

      visit edit_entry_path :id => entry.id

      # wait for AJAX to finish
      expect(find(".source-name").text.length).to be > 0

      # change folios and try to modify folios

      entry.folios = 6666
      entry.save!

      sleep 1.1

      fill_in 'folios', with: '7777'
      first(".save-button").click

      expect(find(".modal-body", visible: true).text.include?("Another change was made to the record while you were working")).to be_truthy
    end

    it "should disallow saving on Edit Page when another change was made (variation 1)" do
      #create_entry

      entry = Entry.last

      visit edit_entry_path :id => entry.id

      # wait for AJAX to finish
      expect(find(".source-name").text.length).to be > 0

      # change folios and try to modify title association record

      entry.folios = 6666
      entry.save!

      sleep 1.1

      find_by_id('add_title').click
      fill_in 'title_0', with: 'changed title'
      first(".save-button").click

      expect(find(".modal-body", visible: true).text.include?("Another change was made to the record while you were working")).to be_truthy
    end

    it "should disallow saving on Edit Page when another change was made (variation 2)" do
      #create_entry

      entry = Entry.last

      visit edit_entry_path :id => entry.id

      # wait for AJAX to finish
      expect(find(".source-name").text.length).to be > 0

      # change title association record and try to modify folios

      entry_title = entry.entry_titles.create({title: "changed title"})

      sleep 1.1

      fill_in 'folios', with: '11111'
      first(".save-button").click

      expect(find(".modal-body", visible: true).text.include?("Another change was made to the record while you were working")).to be_truthy
    end

  end

  context "when user is not logged in" do

    it "should disallow creating Sources if not logged in" do
      visit new_source_path
      expect(page).to have_content("You need to sign in")
    end

    it "should disallow creating Entries if not logged in" do
      visit new_entry_path :source_id => @source.id
      expect(page).to have_content("You need to sign in")
    end

  end

end