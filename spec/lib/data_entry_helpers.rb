module DataEntryHelpers
  def add_name_authority(id, value)
    find_by_id(id).click
    expect(page).to have_content('in Name Authority')
    expect(page).to have_selector('#searchNameAuthority');
    find_by_id('searchNameAuthority').set value
    expect(page).not_to have_content('To begin searching')
    if !page.has_content?("Select #{value}")
      expect(page).to have_content("Propose #{value}")
      find_by_id('propose-name').click
      expect(page).to have_content("This window asks you to create an authorized name")
      click_button('Create')
    else
      find_by_id('selectNameButton').click
    end
    expect(page).not_to have_content("Select #{value}")
    expect(page).to have_css(".well-name-authority", :text => value)
  end

  def add_model_authority(id, value)
    find_by_id(id).click
    expect(page).to have_content('in Name Authority')
    fill_in 'searchModelAuthority', with: value
    expect(page).not_to have_content('To begin searching')
    if !page.has_content?("Select #{value}")
      expect(page).to have_content("Propose #{value}")
      find_by_id('propose-model').click
      expect(page).to have_content("This window asks you to create an authorized name")
      click_button('Create')
    else
      find_by_id('selectModelButton').click
    end
    expect(page).not_to have_content("Select #{value}")
    expect(page).to have_css(".well-name-authority", :text => value)
  end


  # create an entry, filling out all fields
  def create_entry
    visit new_entry_path :source_id => @source.id
    fill_in 'cat_lot_no', with: '123'
    # sale_selling_agent should be auto-populated from source, so we skip it
    #fill_autocomplete_select_or_create_entity 'sale_seller', with: 'Joe2'
    #fill_autocomplete_select_or_create_entity 'sale_buyer', with: 'Joe3'
    
    offset = @source.source_agents.count

    find_by_id('add_sale_agent').click
    add_name_authority("find_sale_agent_name_authority_#{offset}", 'Joe2')
    select 'Seller', from: "sale_agent_role_#{offset}"

    find_by_id('add_sale_agent').click
    add_name_authority("find_sale_agent_name_authority_#{offset + 1}", 'Joe3')
    select 'Buyer', from: "sale_agent_role_#{offset + 1}"

    expect(find("#sale_agent_#{offset}")).to have_content('Joe2')
    expect(find("#sale_agent_#{offset + 1}")).to have_content('Joe3')

#      find_by_id('find_seller_name_authority_0').click
#      fill_in 'searchNameAuthority', with: 'Joe2'
#      find_by_id('selectNameButton').click

#     find_by_id('find_buyer_name_authority_0').click
#     fill_in 'searchNameAuthority', with: 'Joe2'
#     find_by_id('selectNameButton').click

    select 'Yes', from: 'sale_sold'
    fill_in 'sale_date', with: '2014-03-03'
    fill_in 'sale_price', with: '130000'
    select 'USD', from: 'sale_currency'

    find_by_id('add_title').trigger('click')
    fill_in 'title_0', with: 'Book of Hours'
    #find_by_id("add_title_0").click
    find_by_id('add_title').trigger('click')
    fill_in 'title_1', with: 'Bible'

#      fill_autocomplete_select_or_create_entity 'author_0', with: 'Schmoe, Joe'
    find_by_id('add_author').trigger('click')
    add_name_authority('find_author_name_authority_0', 'Schmoe, Joe')
    fill_in 'author_observed_name_0', with: 'Joe Schmoe'
    click_certainty_flag('author_certainty_flags_0')
    select 'Translator', from: 'author_role_0'
    
    find_by_id('add_date').click
    fill_in 'date_observed_date_0', with: 'early 15th century'
    # move focus out of observed_date in order to trigger auto-populate of normalized dates
    page.execute_script %Q{ $('#date_normalized_start_0').trigger('focus') }
    find_by_id('add_artist').click
    fill_in 'artist_observed_name_0', with: 'Chuck'
    #fill_autocomplete_select_or_create_entity 'artist_0', with: 'Schultz, Charles'
    add_name_authority('find_artist_name_authority_0', 'Schultz, Charles')

    find_by_id('add_scribe').click
    fill_in 'scribe_observed_name_0', with: 'Brother Francisco'
    #fill_autocomplete_select_or_create_entity 'scribe_0', with: 'Brother Francis'
    add_name_authority('find_scribe_name_authority_0', 'Brother Francis')

    find_by_id('add_language').click
    #fill_autocomplete_select_or_create_entity 'language_0', with: 'Latin'
    add_model_authority('find_language_name_authority_0', 'Latin')

    find_by_id('add_material').click
    #fill_autocomplete_select_or_create_entity 'material_0', with: 'Parchment'
    select('Parchment', :from => 'material_0')

    find_by_id('add_place').click
    fill_in 'place_observed_name_0', with: 'Somewhere in Italy'
    #fill_autocomplete_select_or_create_entity 'place_0', with: 'Italy'
    add_model_authority('find_place_name_authority_0', 'Italy')
    
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
    
    #fill_autocomplete_select_or_create_entity 'provenance_agent_0', with: 'Somebody, Joseph'
    add_name_authority('find_provenance_name_authority_0', 'Somebody, Joseph')

    click_certainty_flag('provenance_certainty_flags_0')

    find_by_id('add_provenance_date_0').click
    fill_in 'provenance_0_recorded_date_0', with: '1945-06-15'
    sleep 0.4
    fill_in 'provenance_start_date_0', with: '1945-06-15'
    fill_in 'provenance_end_date_0', with: '1965-11-23'
    check 'provenance_direct_transfer_0'

    find_by_id('add_provenance').click
#      fill_autocomplete_select_or_create_entity 'provenance_agent_1', with: "Sotheby's"
    add_name_authority('find_provenance_name_authority_1', "Sotheby's")

    find_by_id('add_provenance_date_1').click
    fill_in 'provenance_1_recorded_date_0', with: '1965'
    fill_in 'provenance_start_date_1', with: '1965-11-23'
    fill_in 'provenance_comment_1', with: 'An historic sale'
    select 'For Sale', from: 'provenance_acquisition_method_1'
    check 'provenance_direct_transfer_1'

    find_by_id('add_provenance').click
    fill_in 'provenance_observed_name_2', with: 'Wild Bill Collector'
    fill_in 'provenance_comment_2', with: 'This is some unknown dude'

    #fill_in 'comment', with: 'This info is correct'

    first(".save-button").click

    expect(find(".modal-title", visible: true)).to have_content("Successfully saved")
  end

  def verify_entry(entry)
    sale = entry.get_sale

    expect(entry.catalog_or_lot_number).to eq('123')
    expect(sale.get_selling_agents_names).to have_content("Sotheby's")
    expect(sale.get_sellers_or_holders.first.agent.name).to eq('Joe2')
    expect(sale.get_buyers.first.agent.name).to eq('Joe3')
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

    #comment = entry.comments.first
    #expect(comment.comment).to eq('This info is correct')

  end

end