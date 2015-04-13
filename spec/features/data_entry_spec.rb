
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
        expect(find(".modal-title", visible: true).text.include?("Create")).to be_truthy
        click_button('Create')
        sleep(0.5)
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

    it "should find source by date on Select Source page" do
      visit new_entry_path
      fill_in 'date', :with => '2013'
      sleep(1)
      expect(page).to have_content @source.title
      click_link('create-entry-link-' + @source.id.to_s)
      expect(page).to have_content "Add an Entry - Fill out details"
    end

    it "should find source by agent on Select Source page" do
      visit new_entry_path
      fill_in 'agent', :with => 'Soth'
      sleep(1)
      expect(page).to have_content @source.title
      click_link('create-entry-link-' + @source.id.to_s)
      expect(page).to have_content "Add an Entry - Fill out details"
    end

    it "should find source by title on Select Source page" do
      visit new_entry_path
      fill_in 'title', :with => 'uniq'
      sleep(1)
      expect(page).to have_content @source.title
      click_link('create-entry-link-' + @source.id.to_s)
      expect(page).to have_content "Add an Entry - Fill out details"
    end

    it "should load New Entry page with an auction catalog Source" do
      source = Source.new(
        title: "xxx",
        source_type: SourceType.auction_catalog,
        source_agents_attributes: [
          {
            agent: Name.find_or_create_agent("aaa"),
            role: SourceAgent::ROLE_SELLING_AGENT,
          },
          {
            agent: Name.find_or_create_agent("bbb"),
            role: SourceAgent::ROLE_SELLER_OR_HOLDER,
          },
          {
            agent: Name.find_or_create_agent("ccc"),
            role: SourceAgent::ROLE_BUYER,
          }
        ]
      )
      source.save!

      visit new_entry_path :source_id => source.id

      expect(page).to have_content 'Add an Entry - Fill out details'

      expect(page).to have_no_field("institution")

      expect(page).to have_select('transaction_type', selected: 'A Sale', disabled: true)

      # should prepopulate Transaction fields
      expect(find_by_id("transaction_selling_agent").value).to eq("aaa")
      expect(find_by_id("transaction_seller").value).to eq("bbb")
      expect(find_by_id("transaction_buyer").value).to eq("ccc")
    end

    it "should load New Entry page with a collection catalog Source" do
      source = Source.new(
        title: "xxx",
        source_type: SourceType.collection_catalog
      )
      source.save!

      visit new_entry_path :source_id => source.id

      expect(page).to have_content 'Add an Entry - Fill out details'

      expect(page).to have_no_field("institution")

      expect(page).to have_select('transaction_type', selected: 'Not a transaction', disabled: true)
    end

    it "should load New Entry page with other published Source" do
      source = Source.find_or_create_by(
        title: "Some Other Published Source",
        date: "2013-11-12",
        source_type: SourceType.other_published
      )
      source.save!

      visit new_entry_path :source_id => source.id

      expect(page).to have_content 'Add an Entry - Fill out details'

      expect(page).to have_field("institution")

      expect(page).to have_select('transaction_type', disabled: false)
    end

    it "should save a new Source (auction catalog)" do
      count = Source.count

      visit new_source_path

      select 'Auction/Sale Catalog', from: 'source_type'
      fill_in 'source_date', with: '2014-02-34'
      fill_in 'title', with: 'Very Rare Books'
      fill_autocomplete_select_or_create_entity 'selling_agent', with: "Sotheby's"
      select "Yes", from: 'whether_mss'
      select "Library", from: 'medium'
      fill_in 'date_accessed', with: "05/01/1990"
      fill_in 'location_institution', with: "University of Pennsylvania"
      fill_in 'location', with: "Philadelphia, USA"
      fill_in 'link', with: "HM851 .L358 2010"
      fill_in 'comments', with: 'This info is correct'

      click_button('Save')

      sleep(1)

      expect(Source.count).to eq(count + 1)

      source = Source.last
      expect(source.source_type).to eq(SourceType.auction_catalog)
      expect(source.date).to eq('20140234')
      expect(source.title).to eq('Very Rare Books')
      expect(source.get_selling_agent.agent.name).to eq("Sotheby's")
      expect(source.whether_mss).to eq("Yes")
      expect(source.medium).to eq(Source::TYPE_MEDIUM_LIBRARY)
      expect(source.date_accessed).to eq("05/01/1990")
      expect(source.location_institution).to eq("University of Pennsylvania")
      expect(source.location).to eq("Philadelphia, USA")
      expect(source.link).to eq("HM851 .L358 2010")
      expect(source.comments).to eq('This info is correct')
    end

    it "should save a new Source (other published source)" do
      count = Source.count

      visit new_source_path

      select 'Other Published Source', from: 'source_type'
      fill_in 'source_date', with: '2014-02-34'
      fill_in 'title', with: 'DeRicci Census'
      fill_in 'author', with: 'Seymour DeRicci'
      select "Yes", from: 'whether_mss'
      select "Library", from: 'medium'
      fill_in 'date_accessed', with: "10/09/2011"
      fill_in 'location_institution', with: "University of Pennsylvania"
      fill_in 'location', with: "Philadelphia, USA"
      fill_in 'link', with: "HM851 .L358 2010"
      fill_in 'comments', with: 'This info is correct'

      click_button('Save')

      sleep(1)

      expect(Source.count).to eq(count + 1)

      source = Source.last
      expect(source.source_type).to eq(SourceType.other_published)
      expect(source.date).to eq('20140234')
      expect(source.title).to eq('DeRicci Census')
      expect(source.author).to eq('Seymour DeRicci')
      expect(source.whether_mss).to eq("Yes")
      expect(source.medium).to eq(Source::TYPE_MEDIUM_LIBRARY)
      expect(source.date_accessed).to eq("10/09/2011")
      expect(source.location_institution).to eq("University of Pennsylvania")
      expect(source.location).to eq("Philadelphia, USA")
      expect(source.link).to eq("HM851 .L358 2010")
      expect(source.comments).to eq('This info is correct')
    end

    it "should save a new Source with no date" do
      count = Source.count

      visit new_source_path

      select 'Other Published Source', from: 'source_type'
      fill_in 'title', with: 'Test source wirh no date'
      fill_in 'author', with: 'Jeff'

      click_button('Save')

      sleep(1)

      expect(Source.count).to eq(count + 1)

      source = Source.last
      expect(source.source_type).to eq(SourceType.other_published)
      expect(source.title).to eq('Test source wirh no date')
      expect(source.author).to eq('Jeff')
    end

    # create an entry, filling out all fields
    def create_entry
      visit new_entry_path :source_id => @source.id
      fill_in 'cat_lot_no', with: '123'
      # transaction_selling_agent should be auto-populated from source, so we skip it
      fill_autocomplete_select_or_create_entity 'transaction_seller', with: 'Joe2'
      fill_autocomplete_select_or_create_entity 'transaction_buyer', with: 'Joe3'
      select 'Yes', from: 'transaction_sold'
      fill_in 'transaction_date', with: '2014-03-03'
      fill_in 'transaction_price', with: '130000'
      select 'USD', from: 'transaction_currency'

      fill_in 'title_0', with: 'Book of Hours'
      find_by_id("add_title_0").click
      fill_in 'title_1', with: 'Bible'
      fill_autocomplete_select_or_create_entity 'author_0', with: 'Schmoe, Joe'
      fill_in 'author_observed_name_0', with: 'Joe Schmoe'
      click_certainty_flag('author_certainty_flags_0')
      select 'Tr', from: 'author_role_0'
      fill_in 'date_observed_date_0', with: 'early 15th century'
      fill_in 'date_0', with: '1425'
      select 'Circa Century', from: 'circa_0'
      fill_in 'artist_observed_name_0', with: 'Chuck'
      fill_autocomplete_select_or_create_entity 'artist_0', with: 'Schultz, Charles'
      fill_in 'scribe_observed_name_0', with: 'Brother Francisco'
      fill_autocomplete_select_or_create_entity 'scribe_0', with: 'Brother Francis'
      fill_autocomplete_select_or_create_entity 'language_0', with: 'Latin'
      fill_autocomplete_select_or_create_entity 'material_0', with: 'Parchment'
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
      fill_autocomplete_select_or_create_entity 'provenance_selling_agent_0', with: "Sotheby's"
      fill_in 'provenance_selling_agent_observed_name_0', with: "Sotheby's Fine Things"
      fill_autocomplete_select_or_create_entity 'provenance_seller_or_holder_0', with: 'Somebody, Joseph'
      fill_in 'provenance_seller_or_holder_observed_name_0', with: 'Joseph H. Somebody'
      fill_autocomplete_select_or_create_entity 'provenance_buyer_0', with: 'Collector, William'
      fill_in 'provenance_buyer_observed_name_0', with: 'Wild Bill Collector'
      fill_in 'provenance_comment_0', with: 'An historic sale'

      fill_in 'comment', with: 'This info is correct'

      click_button('Save')

      # save really can take as long as 2s
      sleep(2)

      expect(find(".modal-title", visible: true).text.include?("Successfully saved")).to be_truthy

    end

    def verify_entry(entry)
      transaction = entry.get_transaction

      expect(entry.catalog_or_lot_number).to eq('123')
      expect(transaction.get_selling_agent.agent.name).to eq("Sotheby's")
      expect(transaction.get_seller_or_holder.agent.name).to eq('Joe2')
      expect(transaction.get_buyer.agent.name).to eq('Joe3')
      expect(transaction.sold).to eq('Yes')
      expect(transaction.start_date).to eq('20140303')
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
      expect(entry_date.observed_date).to eq('early 15th century')
      expect(entry_date.date).to eq('1425')
      expect(entry_date.circa).to eq('CCENT')

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

      provenance = entry.provenance.first
      expect(provenance.start_date).to eq('19450615')
      expect(provenance.end_date).to eq('19651123')
      expect(provenance.get_selling_agent.agent.name).to eq("Sotheby's")
      expect(provenance.get_selling_agent.observed_name).to eq("Sotheby's Fine Things")
      expect(provenance.get_seller_or_holder.agent.name).to eq('Somebody, Joseph')
      expect(provenance.get_seller_or_holder.observed_name).to eq('Joseph H. Somebody')
      expect(provenance.get_buyer.agent.name).to eq('Collector, William')
      expect(provenance.get_buyer.observed_name).to eq('Wild Bill Collector')
      expect(provenance.comment).to eq('An historic sale')

      entry_comment = entry.entry_comments.first
      expect(entry_comment.comment).to eq('This info is correct')
    end

    it "should save an auction catalog Entry" do
      # fill out all the fields and make sure they save to the database

      count = Entry.count

      create_entry

      expect(Entry.count).to eq(count + 1)

      entry = Entry.last

      verify_entry(entry)
    end

    it "should save a collection catalog Entry" do

      source = Source.create!(
        title: "my collection catalog!",
        source_type: SourceType.collection_catalog,
      )

      visit new_entry_path :source_id => source.id

      fill_in 'folios', with: '666'

      click_button('Save')

      # save really can take as long as 2s
      sleep(2)

      expect(find(".modal-title", visible: true).text.include?("Successfully saved")).to be_truthy

      entry = Entry.last
      expect(entry.folios).to eq(666)
      expect(entry.get_transaction).to be_nil
    end

    it "should preserve entry on Edit page when saving without making any changes" do
      count = Entry.count

      create_entry

      expect(Entry.count).to eq(count + 1)

      entry = Entry.last

      visit edit_entry_path :id => entry.id
      click_button('Save')

      # save really can take as long as 2s
      sleep(2)

      expect(find(".modal-title", visible: true).text.include?("Successfully saved")).to be_truthy

      verify_entry(entry)
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
        source: source
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
      click_button('Save')

      # save really can take as long as 2s
      sleep(2)

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
      click_button('Save')

      # save really can take as long as 2s
      sleep(2)

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
      click_button('Save')

      # save really can take as long as 2s
      sleep(2)

      expect(find(".modal-title", visible: true).text.include?("Successfully saved")).to be_truthy

      entry.reload

      expect(entry.entry_titles.count).to eq(1)
      expect(entry.entry_titles.first.title).to eq("Bible")
    end

    it "should disallow saving on Edit Page when another change was made" do
      create_entry

      entry = Entry.last

      visit edit_entry_path :id => entry.id

      sleep(2)

      # change folios and try to modify folios

      entry.folios = 6666
      entry.save!

      fill_in 'folios', with: '7777'

      text = get_alert_text_from do
        click_button('Save')
      end
      expect(text).to match(/Another change was made to the record while you were working/)
    end

    it "should disallow saving on Edit Page when another change was made (variation 1)" do
      create_entry

      entry = Entry.last

      visit edit_entry_path :id => entry.id

      sleep(2)

      # change folios and try to modify title association record

      entry.folios = 6666
      entry.save!

      fill_in 'title_0', with: 'changed title'

      text = get_alert_text_from do
        click_button('Save')
      end
      expect(text).to match(/Another change was made to the record while you were working/)
    end

    it "should disallow saving on Edit Page when another change was made (variation 2)" do
      create_entry

      entry = Entry.last

      visit edit_entry_path :id => entry.id

      sleep(2)

      # change title association record and try to modify folios

      entry_title = entry.entry_titles.last
      entry_title.title = "changed title"
      entry_title.save!

      fill_in 'folios', with: '11111'

      text = get_alert_text_from do
        click_button('Save')
      end
      expect(text).to match(/Another change was made to the record while you were working/)
    end

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
