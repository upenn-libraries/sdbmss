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

    # create an entry, filling out all fields

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

      sleep(1.1)

      find_by_id('add_title').click
      fill_in 'title_0', with: 'Book of Hours'
      #find_by_id("add_title_0").click
      find_by_id('add_title').click
      fill_in 'title_1', with: 'Bible'
      fill_autocomplete_select_or_create_entity 'author_0', with: 'Schmoe, Joe'
      find_by_id('add_author').click
      fill_in 'author_observed_name_0', with: 'Joe Schmoe'
      click_certainty_flag('author_certainty_flags_0')
      select 'Translator', from: 'author_role_0'
      find_by_id('add_date').click
      fill_in 'date_observed_date_0', with: 'early 15th century'
      # move focus out of observed_date in order to trigger auto-populate of normalized dates
      page.execute_script %Q{ $('#date_normalized_start_0').trigger('focus') }
      find_by_id('add_artist').click
      fill_in 'artist_observed_name_0', with: 'Chuck'
      fill_autocomplete_select_or_create_entity 'artist_0', with: 'Schultz, Charles'
      find_by_id('add_scribe').click
      fill_in 'scribe_observed_name_0', with: 'Brother Francisco'
      fill_autocomplete_select_or_create_entity 'scribe_0', with: 'Brother Francis'
      find_by_id('add_language').click
      fill_autocomplete_select_or_create_entity 'language_0', with: 'Latin'
      find_by_id('add_material').click
      fill_autocomplete_select_or_create_entity 'material_0', with: 'Parchment'
      find_by_id('add_place').click
      fill_in 'place_observed_name_0', with: 'Somewhere in Italy'
      fill_autocomplete_select_or_create_entity 'place_0', with: 'Italy'
      find_by_id('add_use').click
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

      find_by_id('add_provenance').click
      fill_in 'provenance_observed_name_0', with: 'Somebody, Joe'
      fill_autocomplete_select_or_create_entity 'provenance_agent_0', with: 'Somebody, Joseph'
      click_certainty_flag('provenance_certainty_flags_0')

      find_by_id('add_provenance_date_0').click
      fill_in 'provenance_0_recorded_date_0', with: '1945-06-15'
      fill_in 'provenance_start_date_0', with: '1945-06-15'
      fill_in 'provenance_end_date_0', with: '1965-11-23'
      check 'provenance_direct_transfer_0'

      find_by_id('add_provenance').click
      fill_autocomplete_select_or_create_entity 'provenance_agent_1', with: "Sotheby's"

      find_by_id('add_provenance_date_1').click
      fill_in 'provenance_1_recorded_date_0', with: '1965'
      fill_in 'provenance_start_date_1', with: '1965-11-23'
      fill_in 'provenance_comment_1', with: 'An historic sale'
      select 'For Sale', from: 'provenance_acquisition_method_1'
      check 'provenance_direct_transfer_1'

      find_by_id('add_provenance').click
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
      expect(provenance.start_date_normalized_start).to eq('1945-06-15')
      expect(provenance.direct_transfer).to eq(true)

      provenance = entry.provenance[1]
      expect(provenance.provenance_agent.name).to eq("Sotheby's")
      expect(provenance.comment).to eq('An historic sale')
      expect(provenance.acquisition_method).to eq(Provenance::TYPE_ACQUISITION_METHOD_FOR_SALE)
      expect(provenance.direct_transfer).to eq(true)

      provenance = entry.provenance[2]
      expect(provenance.observed_name).to eq('Wild Bill Collector')
      expect(provenance.comment).to eq('This is some unknown dude')

      comment = entry.comments.first
      expect(comment.comment).to eq('This info is correct')
    end

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
        f = f.find('.unchecked').click()
        click_button('Undo')

        expect(page).to have_content('Revert to Old Version')
        expect(page).to have_content('10000')
        expect(page).to have_content('123')
        expect(page).to have_content(e.public_id)
      end

      it "should successfully restore the previous version" do
        e = Entry.last

        visit history_entry_path (e)

        f = first('.active', text: 'Folios')
        f = f.find('.unchecked').click()
        click_button('Undo')

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
        f = f.find('.unchecked').click()
        click_button('Undo')

        expect(page).to have_content(e.public_id)
        expect(page).to have_content('Hiiipower')
        expect(page).to have_content('Book of Hours')
      end

      it "should successfully restore the previous association by overwriting the new field" do
        e = Entry.last

        old_count = e.entry_titles.count

        visit history_entry_path (e)

        f = first('.active', text: 'Hiiipower')
        f = f.find('.unchecked').click()
        click_button('Undo')

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
        l = f.first('.history-label')
        expect(l).to have_content('changed Title')
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
        l = f.first('.history-label')
        expect(l).to have_content('deleted Title')
        f = f.find('.unchecked').click()
        click_button('Undo')

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
        l = f.first('.history-label')
        expect(l).to have_content('added Title')
        f = f.find('.unchecked').click()
        click_button('Undo')

        expect(page).to have_content('Book of Hours')
        click_button('Restore')

        sleep(1.1)

        expect(page).not_to have_content('Book of Hours')
        expect(e.entry_titles.count).to eq(old_count - 1)
      end
      # revert successfully, add, and combine
    end

  end
end