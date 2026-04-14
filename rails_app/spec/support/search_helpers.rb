module SearchHelpers
  # These specs intentionally lean on the seeded reference corpus, so keep the
  # record lookup helpers named for that dependency rather than hiding it.
  def open_blacklight_search
    visit root_path
    click_button('search')
    expect(page).to have_selector("#documents")
  end

  def advanced_search_text_fields
    page.all(".advanced-search-field input[type=text]")
  end

  def search_result_count
    page_entries = find(".page-entries").text.match(/of\s(\d+)/)
    page_entries ? page_entries[1].to_i : 0
  end

  def latest_seeded_entry
    Entry.order(id: :desc).first
  end

  def latest_seeded_entries(count = 2)
    Entry.order(id: :desc).limit(count).to_a
  end

  def latest_seeded_source
    Source.order(id: :desc).first
  end

  def latest_seeded_name
    Name.order(id: :desc).first
  end
end
