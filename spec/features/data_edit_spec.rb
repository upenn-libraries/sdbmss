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

    # create an entry, filling out all fields
    def create_entry
      visit new_entry_path :source_id => @source.id
      fill_in 'cat_lot_no', with: '123'
      # sale_selling_agent should be auto-populated from source, so we skip it
      fill_autocomplete_select_or_create_entity 'sale_seller', with: 'Joe2'
      fill_autocomplete_select_or_create_entity 'sale_buyer', with: 'Joe3'
      select 'Yes', from: 'sale_sold'
      fill_in 'sale_date', with: '2014-03-03'
      fill_in 'sale_price', with: '130000'
      select 'USD', from: 'sale_currency'

      fill_in 'title_0', with: 'Book of Hours'
      find_by_id("add_title_0").click
      fill_in 'title_1', with: 'Bible'
      fill_autocomplete_select_or_create_entity 'author_0', with: 'Schmoe, Joe'
      fill_in 'author_observed_name_0', with: 'Joe Schmoe'
      click_certainty_flag('author_certainty_flags_0')
      select 'Translator', from: 'author_role_0'
      fill_in 'date_observed_date_0', with: 'early 15th century'
      # move focus out of observed_date in order to trigger auto-populate of normalized dates
      page.execute_script %Q{ $('#date_normalized_start_0').trigger('focus') }
      fill_in 'artist_observed_name_0', with: 'Chuck'
      fill_autocomplete_select_or_create_entity 'artist_0', with: 'Schultz, Charles'
      fill_in 'scribe_observed_name_0', with: 'Brother Francisco'
      fill_autocomplete_select_or_create_entity 'scribe_0', with: 'Brother Francis'
      fill_autocomplete_select_or_create_entity 'language_0', with: 'Latin'
      fill_autocomplete_select_or_create_entity 'material_0', with: 'Parchment'
      fill_in 'place_observed_name_0', with: 'Somewhere in Italy'
      fill_autocomplete_select_or_create_entity 'place_0', with: 'Italy'
      fill_in 'use_0', with: 'Some mysterious office or other'

      fill_in 'folios', with: '123'
      fill_in 'num_lines', with: '3'
      fill_in 'num_columns', with: '2'
      fill_in 'height', with: '200'
      fill_in 'width', with: '300'
      select 'Folio', from: 'alt_size'
      fill_in 'miniatures_fullpage', with: '6'
      fill_in 'miniatures_large', with: '7'
      fill_in 'miniatures_small', with: '8'
      fill_in 'miniatures_unspec_size', with: '9'
      fill_in 'initials_historiated', with: '10'
      fill_in 'initials_decorated', with: '11'
      fill_in 'manuscript_binding', with: 'Velvet'
      fill_in 'manuscript_link', with: 'http://something.com'
      fill_in 'other_info', with: 'Other stuff'

      fill_in 'provenance_observed_name_0', with: 'Somebody, Joe'
      fill_autocomplete_select_or_create_entity 'provenance_agent_0', with: 'Somebody, Joseph'
      click_certainty_flag('provenance_certainty_flags_0')
      fill_in 'provenance_start_date_0', with: '1945-06-15'
      fill_in 'provenance_end_date_0', with: '1965-11-23'
      check 'provenance_direct_transfer_0'

      find_by_id("add_provenance_0").click
      fill_autocomplete_select_or_create_entity 'provenance_agent_1', with: "Sotheby's"
      fill_in 'provenance_start_date_1', with: '1965-11-23'
      fill_in 'provenance_comment_1', with: 'An historic sale'
      select 'For Sale', from: 'provenance_acquisition_method_1'
      check 'provenance_direct_transfer_1'

      find_by_id("add_provenance_0").click
      fill_in 'provenance_observed_name_2', with: 'Wild Bill Collector'
      fill_in 'provenance_comment_2', with: 'This is some unknown dude'

      fill_in 'comment', with: 'This info is correct'

      first(".save-button").click

      sleep(1.5)
      expect(find(".modal-title", visible: true).text.include?("Successfully saved")).to be_truthy

    end

    def verify_entry(entry)
      sale = entry.get_sale

      expect(entry.catalog_or_lot_number).to eq('123')
      expect(sale.get_selling_agent.agent.name).to eq("Sotheby's")
      expect(sale.get_seller_or_holder.agent.name).to eq('Joe2')
      expect(sale.get_buyer.agent.name).to eq('Joe3')
      expect(sale.sold).to eq('Yes')
      expect(sale.date).to eq('20140303')
      expect(sale.price).to eq(130000)
      expect(sale.currency).to eq('USD')

      entry_titles = entry.entry_titles
      expect(entry_titles[0].title).to eq('Book of Hours')
      expect(entry_titles[1].title).to eq('Bible')

      entry_author = entry.entry_authors.first
      expect(entry_author.author.name).to eq('Schmoe, Joe')
      expect(entry_author.observed_name).to eq('Joe Schmoe')
      expect(entry_author.role).to eq('Tr')
      expect(entry_author.uncertain_in_source).to eq(true)

      entry_date = entry.entry_dates.first
      expect(entry_date.observed_date).to eq('early 15th century')
      expect(entry_date.date_normalized_start).to eq('1400')
      expect(entry_date.date_normalized_end).to eq('1426')

      entry_artist = entry.entry_artists.first
      expect(entry_artist.observed_name).to eq('Chuck')
      expect(entry_artist.artist.name).to eq('Schultz, Charles')

      entry_scribe = entry.entry_scribes.first
      expect(entry_scribe.observed_name).to eq('Brother Francisco')
      expect(entry_scribe.scribe.name).to eq('Brother Francis')

      entry_language = entry.entry_languages.first
      expect(entry_language.language.name).to eq('Latin')

      entry_material = entry.entry_materials.first
      expect(entry_material.material).to eq('Parchment')

      entry_place = entry.entry_places.first
      expect(entry_place.observed_name).to eq('Somewhere in Italy')
      expect(entry_place.place.name).to eq('Italy')

      entry_use = entry.entry_uses.first
      expect(entry_use.use).to eq('Some mysterious office or other')

      expect(entry.folios).to eq(123)
      expect(entry.num_lines).to eq(3)
      expect(entry.num_columns).to eq(2)
      expect(entry.height).to eq(200)
      expect(entry.width).to eq(300)
      expect(entry.alt_size).to eq('F')
      expect(entry.miniatures_fullpage).to eq(6)
      expect(entry.miniatures_large).to eq(7)
      expect(entry.miniatures_small).to eq(8)
      expect(entry.miniatures_unspec_size).to eq(9)
      expect(entry.initials_historiated).to eq(10)
      expect(entry.initials_decorated).to eq(11)
      expect(entry.manuscript_binding).to eq('Velvet')
      expect(entry.manuscript_link).to eq('http://something.com')
      expect(entry.other_info).to eq('Other stuff')

      expect(entry.provenance.count).to eq(3)

      provenance = entry.provenance.first
      expect(provenance.observed_name).to eq('Somebody, Joe')
      expect(provenance.provenance_agent.name).to eq('Somebody, Joseph')
      expect(provenance.uncertain_in_source).to be_truthy
      expect(provenance.start_date).to eq('1945-06-15')
      expect(provenance.end_date).to eq('1965-11-23')
      expect(provenance.start_date_normalized_start).to eq('1945-06-15')
      expect(provenance.start_date_normalized_end).to eq('1945-06-16')
      expect(provenance.direct_transfer).to eq(true)

      provenance = entry.provenance[1]
      expect(provenance.provenance_agent.name).to eq("Sotheby's")
      expect(provenance.start_date).to eq('1965-11-23')
      expect(provenance.comment).to eq('An historic sale')
      expect(provenance.acquisition_method).to eq(Provenance::TYPE_ACQUISITION_METHOD_FOR_SALE)
      expect(provenance.direct_transfer).to eq(true)

      provenance = entry.provenance[2]
      expect(provenance.observed_name).to eq('Wild Bill Collector')
      expect(provenance.comment).to eq('This is some unknown dude')

      comment = entry.comments.first
      expect(comment.comment).to eq('This info is correct')
    end

    it "should edit an existing Source" do
      source = Source.create!(
        date: "20141215",
        title: "my existing source",
        source_type: SourceType.auction_catalog,
        created_by: @user,
      )

      visit edit_source_path :id => source.id

      expect(page).to have_content("Edit " + source.public_id)

      expect(page).to have_select('source_type', disabled: true, selected: 'Auction/Sale Catalog')
      expect(page).to have_field('source_date', with: '2014-12-15')
      expect(page).to have_field('title', with: 'my existing source')

      click_button('Save')

      expect(find(".modal-title", visible: true).text.include?("Successfully saved")).to be_truthy

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
      count = Entry.count

      create_entry

      expect(Entry.count).to eq(count + 1)

      entry = Entry.last

      visit edit_entry_path :id => entry.id

      first(".save-button").click

      expect(find(".modal-title", visible: true).text.include?("Successfully saved")).to be_truthy

      verify_entry(entry)
    end

    it "should create history when updating an Entry" do
      count = Entry.count

      create_entry

      expect(Entry.count).to eq(count + 1)

      entry = Entry.last

      old_title = entry.entry_titles.first.title

      visit edit_entry_path :id => entry.id

      fill_in 'title_0', with: 'Changed Book'

      first(".save-button").click

      expect(find(".modal-title", visible: true).text.include?("Successfully saved")).to be_truthy

      entry.reload

      visit history_entry_path :id => entry.id

      # should display in 3rd row
      expect(all(:xpath, "//tr")[2].all(:xpath, ".//td")[2].text).to eq("changed Title")
      expect(all(:xpath, "//tr")[2].all(:xpath, ".//td")[3].text).to eq("Title: from #{old_title} to Changed Book")
    end

    it "should pre-populate transaction_type on Edit page" do
      count = Entry.count

      # create an Unpublished source, which allows selection of
      # transaction_type
      source = Source.create!(
        title: "test unpublished source",
        source_type: SourceType.unpublished,
      )
      entry = Entry.create!(
        transaction_type: Entry::TYPE_TRANSACTION_GIFT,
        source: source,
        created_by_id: @user.id,
      )

      visit edit_entry_path :id => entry.id

      expect(page).to have_select('transaction_type', selected: 'A Gift')
    end

    it "should remove a title on Edit page" do
      count = Entry.count

      create_entry

      expect(Entry.count).to eq(count + 1)

      entry = Entry.last

      visit edit_entry_path :id => entry.id

      # mock out the confirm dialogue
      page.evaluate_script('window.confirm = function() { return true; }')

      find_by_id("delete_title_0").click

      first(".save-button").click

      expect(find(".modal-title", visible: true).text.include?("Successfully saved")).to be_truthy

      entry.reload

      expect(entry.entry_titles.count).to eq(1)
      expect(entry.entry_titles.first.title).to eq("Bible")
    end

    it "should clear out a title on Edit Page" do
      count = Entry.count

      create_entry

      expect(Entry.count).to eq(count + 1)

      entry = Entry.last

      visit edit_entry_path :id => entry.id

      # clear out the title field; this should result in deletion of
      # underlying entry_title record
      fill_in 'title_0', with: ''

      first(".save-button").click

      expect(find(".modal-title", visible: true).text.include?("Successfully saved")).to be_truthy

      entry.reload

      expect(entry.entry_titles.count).to eq(1)
      expect(entry.entry_titles.first.title).to eq("Bible")
    end

    it "should clear out a title on Edit Page" do
      count = Entry.count

      create_entry

      expect(Entry.count).to eq(count + 1)

      entry = Entry.last

      visit edit_entry_path :id => entry.id

      # clear out the title field; this should result in deletion of
      # underlying entry_title record
      fill_in 'title_0', with: ''

      first(".save-button").click

      expect(find(".modal-title", visible: true).text.include?("Successfully saved")).to be_truthy

      entry.reload

      expect(entry.entry_titles.count).to eq(1)
      expect(entry.entry_titles.first.title).to eq("Bible")
    end

    it "should clear out a Name Authority (autocomplete) field" do
      count = Entry.count

      create_entry

      expect(Entry.count).to eq(count + 1)

      entry = Entry.last

      visit edit_entry_path :id => entry.id

      fill_in 'author_observed_name_0', with: "Joe"
      fill_in 'author_0', with: '     '
      fill_autocomplete('author_0', with: '     ')

      expect(find_field('author_0').value).to eq('     ')

      first(".save-button").click

      expect(find(".modal-title", visible: true).text.include?("Successfully saved")).to be_truthy

      entry.reload

      entry = Entry.last

      expect(entry.entry_authors.count).to eq(1)
      expect(entry.entry_authors.first.author_id).to eq(nil)
    end

    it "should warn when editing Entry to have same catalog number as existing Entry" do
      create_entry

      visit new_entry_path :source_id => @source.id

      # make a new entry w/ same Source but diff catalog number
      fill_in 'cat_lot_no', with: "124"
      first(".save-button").click
      expect(find(".modal-title", visible: true).text.include?("Successfully saved")).to be_truthy

      visit edit_entry_path :id => Entry.last.id
      fill_in 'cat_lot_no', with: "123"
      find_by_id('title_0').trigger('focus')

      expect(page).to have_content "Warning! Another entry with that catalog number already exists."

      # change it back to a new number so msg goes away
      fill_in 'cat_lot_no', with: "124"
      find_by_id('title_0').trigger('focus')

      expect(page).not_to have_content "Warning! Another entry with that catalog number already exists."
    end

    it "should disallow saving on Edit Page when another change was made" do
      create_entry

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
      create_entry

      entry = Entry.last

      visit edit_entry_path :id => entry.id

      # wait for AJAX to finish
      expect(find(".source-name").text.length).to be > 0

      # change folios and try to modify title association record

      entry.folios = 6666
      entry.save!

      sleep 1.1

      fill_in 'title_0', with: 'changed title'
      first(".save-button").click

      expect(find(".modal-body", visible: true).text.include?("Another change was made to the record while you were working")).to be_truthy
    end

    it "should disallow saving on Edit Page when another change was made (variation 2)" do
      create_entry

      entry = Entry.last

      visit edit_entry_path :id => entry.id

      # wait for AJAX to finish
      expect(find(".source-name").text.length).to be > 0

      # change title association record and try to modify folios

      entry_title = entry.entry_titles.last
      entry_title.title = "changed title"
      entry_title.save!

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