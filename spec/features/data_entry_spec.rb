
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
      found = all("ul.ui-autocomplete li.ui-menu-item", visible: true).any? { |li| li.text == value }
      if found
        value_escaped = value.gsub("'", "\\\\'")
        selector = %Q{ul.ui-autocomplete:visible li.ui-menu-item:contains("#{value_escaped}")}
      else
        # select the 1st option, which should pop up the modal to create an entity
        selector = %Q{ul.ui-autocomplete:visible li.ui-menu-item:eq(0)}
      end
      page.execute_script %Q{ $('#{selector}').click() }

      if !found
        find(".modal-title", visible: true).text.include? "Create"
        click_button('Create')
        sleep(0.5)
      end
    end
    #page.save_screenshot("screenshot_#{field}.png")
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
      source_type: Source::TYPE_AUCTION_CATALOG
    )
  end

  context "when user is logged in" do

    before :each do
      page.driver.resize_window(1024, 768)

      visit new_user_session_path
      fill_in 'user_login', :with => @user.username
      fill_in 'user_password', :with => 'somethingunguessable'
      click_button 'Log in'
      expect(page).to have_content 'Signed in successfully'
    end

    after :each do
      page.reset!
    end

    it "should find source on Select Source page" do
      visit new_entry_path
      fill_in 'date', :with => '2013'
      sleep(1)
      expect(page).to have_content @source.title
      click_link('create-entry-link-' + @source.id.to_s)
      expect(page).to have_content "Add an Entry - Fill out details"
    end

    it "should load New Entry page with an auction catalog Source" do
      source = Source.new(
        title: "xxx",
        source_type: Source::TYPE_AUCTION_CATALOG,
        source_agents_attributes: [
          {
            agent: Agent.find_or_create_by(name: "aaa"),
            role: SourceAgent::ROLE_SELLER_AGENT,
          },
          {
            agent: Agent.find_or_create_by(name: "bbb"),
            role: SourceAgent::ROLE_SELLER_OR_HOLDER,
          },
          {
            agent: Agent.find_or_create_by(name: "ccc"),
            role: SourceAgent::ROLE_BUYER,
          }
        ]
      )
      source.save!

      visit new_entry_path :source_id => source.id

      expect(page).to have_content 'Add an Entry - Fill out details'

      expect(page).to have_content 'Transaction Information'

      # should prepopulate Transaction fields
      expect(find_by_id("transaction_seller_agent").value).to eq("aaa")
      expect(find_by_id("transaction_seller").value).to eq("bbb")
      expect(find_by_id("transaction_buyer").value).to eq("ccc")
    end

    it "should load New Entry page with a institutional catalog Source" do
      source = Source.new(
        title: "xxx",
        source_type: Source::TYPE_COLLECTION_CATALOG
      )
      source.save!

      visit new_entry_path :source_id => source.id

      expect(page).to have_content 'Add an Entry - Fill out details'

      expect(page).to have_no_content 'Transaction Information'
    end

    it "should save an auction catalog Source" do
      count = Source.count

      visit new_source_path

      select 'Auction/Sale Catalog', from: 'source_type'
      fill_in 'source_date', with: '2014-02-34'
      fill_in 'title', with: 'Very Rare Books'
      fill_autocomplete_select_or_create_entity 'seller_agent', with: "Sotheby's"
      select "Yes", from: 'whether_mss'
      fill_in 'current_location', with: "University of Pennsylvania"
      fill_in 'location_city', with: "Philadelphia"
      fill_in 'location_country', with: "USA"
      fill_in 'link', with: "HM851 .L358 2010"
      fill_in 'cataloging_type', with: "print"
      fill_in 'electronic_catalog_format', with: "test"
      select "No", from: 'electronic_publicly_available'
      fill_in 'comments', with: 'This info is correct'

      click_button('Save')

      sleep(1)

      expect(Source.count).to eq(count + 1)

      source = Source.last
      expect(source.source_type).to eq(Source::TYPE_AUCTION_CATALOG)
      expect(source.date).to eq('20140234')
      expect(source.title).to eq('Very Rare Books')
      expect(source.get_seller_agent.agent.name).to eq("Sotheby's")
      expect(source.whether_mss).to eq("Yes")
      expect(source.current_location).to eq("University of Pennsylvania")
      expect(source.location_city).to eq("Philadelphia")
      expect(source.location_country).to eq("USA")
      expect(source.link).to eq("HM851 .L358 2010")
      expect(source.cataloging_type).to eq("print")
      expect(source.electronic_catalog_format).to eq("test")
      expect(source.electronic_publicly_available).to eq("No")
      expect(source.comments).to eq('This info is correct')
    end

    it "should save an Entry" do
      # fill out all the fields and make sure they save to the database

      count = Entry.count

      visit new_entry_path :source_id => @source.id
      fill_in 'cat_lot_no', with: '123'
      fill_autocomplete_select_or_create_entity 'transaction_seller_agent', with: "Sotheby's"
      fill_autocomplete_select_or_create_entity 'transaction_seller', with: 'Joe2'
      fill_autocomplete_select_or_create_entity 'transaction_buyer', with: 'Joe3'
      select 'No', from: 'transaction_sold'
      fill_in 'transaction_price', with: '130000'
      select 'USD', from: 'transaction_currency'

      fill_in 'title_0', with: 'Book of Hours'
      find_by_id("add_title_0").click
      fill_in 'title_1', with: 'Bible'
      fill_autocomplete_select_or_create_entity 'author_0', with: 'Schmoe, Joe'
      fill_in 'author_observed_name_0', with: 'Joe Schmoe'
      find_by_id('author_certainty_flags_0').click
      select 'Tr', from: 'author_role_0'
      fill_in 'date_0', with: '1425'
      select 'Circa Century', from: 'circa_0'
      fill_autocomplete_select_or_create_entity 'artist_0', with: 'Schultz, Charles'
      fill_autocomplete_select_or_create_entity 'scribe_0', with: 'Brother Francis'
      fill_autocomplete_select_or_create_entity 'language_0', with: 'Latin'
      select 'Parchment', from: 'material_0'
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

      fill_in 'provenance_start_date_0', with: '19450615'
      fill_in 'provenance_end_date_0', with: '19651123'
      fill_autocomplete_select_or_create_entity 'provenance_seller_agent_0', with: "Sotheby's"
      fill_in 'provenance_seller_agent_observed_name_0', with: "Sotheby's Fine Things"
      fill_autocomplete_select_or_create_entity 'provenance_seller_or_holder_0', with: 'Somebody, Joseph'
      fill_in 'provenance_seller_or_holder_observed_name_0', with: 'Joseph H. Somebody'
      fill_autocomplete_select_or_create_entity 'provenance_buyer_0', with: 'Collector, William'
      fill_in 'provenance_buyer_observed_name_0', with: 'Wild Bill Collector'
      fill_in 'provenance_comment_0', with: 'An historic sale'

      fill_in 'comment', with: 'This info is correct'

      click_button('Save')

      # save really can take as long as 2s
      sleep(2)

      find(".modal-title", visible: true).text.include? "Successfully saved"

      expect(Entry.count).to eq(count + 1)

      entry = Entry.last
      transaction = entry.get_transaction

      expect(entry.catalog_or_lot_number).to eq('123')
      expect(transaction.get_seller_agent.agent.name).to eq("Sotheby's")
      expect(transaction.get_seller_or_holder.agent.name).to eq('Joe2')
      expect(transaction.get_buyer.agent.name).to eq('Joe3')
      expect(transaction.sold).to eq('No')
      expect(transaction.price).to eq(130000)
      expect(transaction.currency).to eq('USD')

      entry_titles = entry.entry_titles
      expect(entry_titles[0].title).to eq('Book of Hours')
      expect(entry_titles[1].title).to eq('Bible')

      entry_author = entry.entry_authors.first
      expect(entry_author.author.name).to eq('Schmoe, Joe')
      expect(entry_author.observed_name).to eq('Joe Schmoe')
      expect(entry_author.role).to eq('Tr')
      expect(entry_author.uncertain_in_source).to eq(true)

      entry_date = entry.entry_dates.first
      expect(entry_date.date).to eq('1425')
      expect(entry_date.circa).to eq('CCENT')

      entry_scribe = entry.entry_scribes.first
      expect(entry_scribe.scribe.name).to eq('Brother Francis')

      entry_language = entry.entry_languages.first
      expect(entry_language.language.name).to eq('Latin')

      entry_material = entry.entry_materials.first
      expect(entry_material.material).to eq('Parchment')

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

      provenance = entry.get_provenance.first
      expect(provenance.start_date).to eq('19450615')
      expect(provenance.end_date).to eq('19651123')
      expect(provenance.get_seller_agent.agent.name).to eq("Sotheby's")
      expect(provenance.get_seller_agent.observed_name).to eq("Sotheby's Fine Things")
      expect(provenance.get_seller_or_holder.agent.name).to eq('Somebody, Joseph')
      expect(provenance.get_seller_or_holder.observed_name).to eq('Joseph H. Somebody')
      expect(provenance.get_buyer.agent.name).to eq('Collector, William')
      expect(provenance.get_buyer.observed_name).to eq('Wild Bill Collector')
      expect(provenance.comment).to eq('An historic sale')

      entry_comment = entry.entry_comments.first
      expect(entry_comment.comment).to eq('This info is correct')
      #puts "TEST FINISHED"
    end

    it "should prepopulate Edit Entry page"

    it "should validate when saving Entry"
  end

  context "when user is not logged in" do

    it "should disallow creating Sources if not logged in", :skip_before do
      visit new_source_path
      expect(page).to have_content("You need to sign in")
    end

    it "should disallow creating Entries if not logged in", :skip_before do
      visit new_entry_path :source_id => @source.id
      expect(page).to have_content("You need to sign in")
    end

  end

end
