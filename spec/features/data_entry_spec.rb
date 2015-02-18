
require "rails_helper"

describe "Data entry", :js => true do

  # Fill an autocomplete field and select an option.
  # option keys:
  # :with = value to use for filling in field
  # :select = select the element with given text value
  # :select_nth = select the nth element in options
  # :wait = seconds to sleep after DOM events
  def fill_autocomplete(field, options = {})
    # adapted from http://ruby-journal.com/how-to-do-jqueryui-autocomplete-with-capybara-2/
    #
    # This version here works with the autocomplete in jQuery UI
    # 1.11.2. WARNING: This code is very fragile! We have to simulate
    # interaction with DOM EXACTLY.
    wait = options[:wait] || 1

    page.execute_script %Q{ $('##{field}').trigger('focus') }

    # capybara's fill_in doesn't trigger the DOM events autocomplete
    # listens for; use send_keys instead
    find_by_id(field).native.send_keys(options[:with])

    # wait for an autocomplete UL element to appear
    find('ul.ui-autocomplete', visible: true)

    if options[:select] || options[:select_nth]
      if options[:select]
        selector = %Q{ul.ui-autocomplete:visible li.ui-menu-item:contains("#{options[:select]}")}
      elsif options[:select_nth]
        selector = %Q{ul.ui-autocomplete:visible li.ui-menu-item:eq(#{options[:select_nth]})}
      end
      page.execute_script %Q{ $('#{selector}').click() }
      # give browser time to process the click
      sleep(wait)
    end
  end

  # This triggers autocomplete, selects the 1st item, and clicks Save
  # on the popup that should appear
  def fill_autocomplete_select_or_create_entity(field, options = {})
    options[:select_nth] = 0

    # TODO: logic for select OR create
    fill_autocomplete(field, options)

    page.save_screenshot("screenshot_#{field}.png")

    click_button('Create')
    sleep(1)
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

  before :each do
    page.driver.resize_window(1024, 768)

    visit new_user_session_path
    fill_in 'user_login', :with => @user.username
    fill_in 'user_password', :with => 'somethingunguessable'
    click_button 'Log in'
    expect(page).to have_content 'Signed in successfully'
  end

  it "should find source on Select Source page" do
    visit new_entry_path
    fill_in 'date', :with => '2013'
    sleep(1)
    expect(page).to have_content @source.title
    click_link('create-entry-link-' + @source.id.to_s)
    expect(page).to have_content "Add an Entry - Fill out details"
  end

  it "should load New Entry page with Transaction fields prepopulated"

  it "should load New Entry page correctly with an auction catalog Source" do
    source = Source.new(
      title: "xxx",
      source_type: Source::TYPE_AUCTION_CATALOG
    )
    source.save!

    visit new_entry_path :source_id => source.id

    expect(page).to have_content 'Add an Entry - Fill out details'

    expect(page).to have_content 'Transaction Information'

    # TODO: save it and make sure there IS a transaction

  end

  it "should load New Entry page correctly with a institutional catalog Source" do
    source = Source.new(
      title: "xxx",
      source_type: Source::TYPE_COLLECTION_CATALOG
    )
    source.save!

    visit new_entry_path :source_id => source.id

    expect(page).to have_content 'Add an Entry - Fill out details'

    expect(page).to have_no_content 'Transaction Information'

    # TODO: save it and make sure there's no transaction

  end

  it "should save a Source correctly"

  it "should save an Entry correctly" do
    count = Entry.count

    visit new_entry_path :source_id => @source.id
    fill_in 'cat_lot_no', with: '123'
    fill_autocomplete_select_or_create_entity 'transaction_seller_agent', with: 'Joe1'
    fill_autocomplete_select_or_create_entity 'transaction_seller', with: 'Joe2'
    fill_autocomplete_select_or_create_entity 'transaction_buyer', with: 'Joe3'
    select 'No', from: 'transaction_sold'
    fill_in 'transaction_price', with: '130000'
    select 'USD', from: 'transaction_currency'

    fill_in 'title_0', with: 'Book of Hours'
    fill_autocomplete_select_or_create_entity 'author_0', with: 'Schmoe, Joe'
    fill_in 'author_observed_name_0', with: 'Joe Schmoe'
    fill_in 'author_role_0', with: 'Tr'
    fill_in 'date_0', with: '1425'
    select 'Circa Century', from: 'circa_0'
    fill_autocomplete_select_or_create_entity 'artist_0', with: 'Schultz, Charles'
    fill_autocomplete_select_or_create_entity 'scribe_0', with: 'Brother Francis'

    page.driver.scroll_to(0, 2000)

    fill_autocomplete_select_or_create_entity 'language_0', with: 'Chinese'
    select 'Parchment', from: 'material_0'

    click_button('Save')

    # it really does take 2s
    sleep(2)

    find(".modal-title", visible: true).text.include? "Successfully saved"

    expect(Entry.count).to eq(count + 1)

    entry = Entry.last
    transaction = entry.get_transaction

    expect(entry.catalog_or_lot_number).to eq('123')
    expect(transaction.get_seller_agent.agent.name).to eq('Joe1')
    expect(transaction.get_seller_or_holder.agent.name).to eq('Joe2')
    expect(transaction.get_buyer.agent.name).to eq('Joe3')
    expect(transaction.sold).to eq('No')
    expect(transaction.price).to eq(130000)
    expect(transaction.currency).to eq('USD')

    entry_title = entry.entry_titles.first
    expect(entry_title.title).to eq('Book of Hours')

    entry_author = entry.entry_authors.first
    expect(entry_author.author.name).to eq('Schmoe, Joe')
    expect(entry_author.observed_name).to eq('Joe Schmoe')
    expect(entry_author.role).to eq('Tr')

    entry_date = entry.entry_dates.first
    expect(entry_date.date).to eq('1425')
    expect(entry_date.circa).to eq('CCENT')

    entry_scribe = entry.entry_scribes.first
    expect(entry_scribe.scribe.name).to eq('Brother Francis')

    entry_language = entry.entry_languages.first
    expect(entry_language.language.name).to eq('Chinese')

    entry_material = entry.entry_materials.first
    expect(entry_material.material).to eq('Parchment')

    #puts "TEST FINISHED"
  end

  it "should disallow creating Entries if not logged in"

  it "should validate when saving Entry"

end
