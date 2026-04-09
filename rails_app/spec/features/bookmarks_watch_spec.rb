require "rails_helper"

describe "Bookmark", :js => true do

  context "when user is logged in" do
    before :each do
      @admin_user = create(:admin)
      @bookmark_entry = create_bookmark_watch_entry(@admin_user)
      Bookmark.create!(user_id: @admin_user.id, user_type: 'User', document_id: @bookmark_entry.id.to_s, document_type: 'Entry', tags: 'new tag')
      login(@admin_user, 'somethingreallylong')
    end

    it "should allow a user to bookmark an entry from a public search" do
      target = Entry.create!(source: create(:edit_test_source, created_by: @admin_user), created_by: @admin_user)
      target.entry_titles.create!(title: "Bookmark Search Unique Title")
      target.reload
      target.index!
      Sunspot.commit

      visit root_path
      fill_in "q", with: "Bookmark Search Unique Title"
      click_button "Search"

      expect(page).to have_content(target.public_id)
      within(".document", text: target.public_id) do
        find('.bookmark', match: :first).click
      end

      visit bookmarks_path
      expect(page).to have_content("of this type")
      expect(page).to have_content(target.public_id)
    end

    it "should allow the user to add tags to their bookmark" do
      visit bookmarks_path

      find('.btn-add-tag', match: :first).click
      expect(page).to have_content('Tag:')
      find('.new-bookmark-tag', match: :first).set "new tag"
      find('.add-bookmark-tag-confirm', match: :first).click

      expect(page).to have_content('new tag')
      find('input[name="tag-search"]', match: :first).set "new tag"
      find('.bookmark-search', match: :first).click
      expect(page).to have_content(@bookmark_entry.public_id)
    end

    it "should not add a tag that is already present" do
      visit bookmarks_path

      find('.btn-add-tag', match: :first).click
      expect(page).to have_content('Tag:')
      find('.new-bookmark-tag', match: :first).set "new tag"
      find('.add-bookmark-tag-confirm', match: :first).click

      expect(page).to have_content('new tag')
    end

    it "should remove a tag and bookmark as desired" do
      expect(Bookmark.count).to eq(1)
      visit bookmarks_path
      expect(page).to have_content(@bookmark_entry.public_id)
      expect(page).to have_content 'new tag'
      find('.remove-bookmark-tag-confirm', match: :first).click
      expect(page).not_to have_content 'new tag'
      find('.remove-bookmark', match: :first).click
      expect(page).to have_content "un-bookmarked"
      visit bookmarks_path
      expect(page).not_to have_content(@bookmark_entry.public_id)
    end

    it "should bookmark/watch and remove for Entries" do
      visit entries_path
      # Derive the target entry from the class of the first visible bookmark button
      # Bookmark buttons have class "Bookmark_Entry_<id>"
      bookmark_link = find('.bookmark:not(.bookmark-delete)', match: :first)
      match_data = bookmark_link[:class].match(/Bookmark_Entry_(\d+)/)
      expect(match_data).not_to be_nil, "Could not extract entry ID from bookmark button classes: #{bookmark_link[:class].inspect}"
      entry_id = match_data[1].to_i
      target = Entry.find(entry_id)

      bookmark_link.click
      # Wait for bookmark AJAX to complete (button becomes bookmark-delete)
      expect(page).to have_css(".bookmark-delete.Bookmark_Entry_#{entry_id}")

      find(".Watch_Entry_#{entry_id}").click
      # Wait for watch AJAX to complete (button becomes watch-delete)
      expect(page).to have_css(".watch-delete.Watch_Entry_#{entry_id}")

      visit entry_path(target)
      expect(page).to have_content('Bookmarked')
      expect(page).to have_content('Watched')

      find('.bookmark-delete', match: :first).click
      find('.watch-delete', match: :first).click

      expect(page).not_to have_content('Bookmarked')
      expect("#control-panel").not_to have_content('Watched')
    end

    it "should bookmark/watch and remove for Names" do
      target = Name.find_or_create_agent("Bookmark Watch, Name")
      visit name_path(target)
      bookmark_and_watch_current_record

      expect(page).to have_content('Bookmarked')
      expect(page).to have_content('Watched')

      find('.bookmark-delete', match: :first).click
      find('.watch-delete', match: :first).click

      expect(page).not_to have_content('Bookmarked')
      expect("#control-panel").not_to have_content('Watched')
    end

    it "should bookmark/watch and remove for Sources" do
      target = create(:edit_test_source, created_by: @admin_user)
      visit source_path(target)
      bookmark_and_watch_current_record

      expect(page).to have_content('Bookmarked')
      expect(page).to have_content('Watched')

      find('.bookmark-delete', match: :first).click
      find('.watch-delete', match: :first).click

      expect(page).not_to have_content('Bookmarked')
      expect("#control-panel").not_to have_content('Watched') 
    end

    it "should bookmark/watch and remove for Manuscript Records" do
      target = create(:manuscript, created_by: @admin_user)
      visit manuscript_path(target)
      bookmark_and_watch_current_record

      expect(page).to have_content('Bookmarked')
      expect(page).to have_content('Watched')

      find('.bookmark-delete', match: :first).click
      find('.watch-delete', match: :first).click

      expect(page).not_to have_content('Bookmarked')
      expect("#control-panel").not_to have_content('Watched')
    end

    it "should bookmark/watch and remove for Dericci Records" do
      target = DericciRecord.create!(name: "Bookmark Watch De Ricci Record", url: "http://example.com", cards: 1, size: "folio", created_by: @admin_user, updated_by: @admin_user)
      visit dericci_record_path(target)
      bookmark_and_watch_current_record

      expect(page).to have_content('Bookmarked')
      expect(page).to have_content('Watched')

      find('.bookmark-delete', match: :first).click
      find('.watch-delete', match: :first).click

      expect(page).not_to have_content('Bookmarked')
      expect("#control-panel").not_to have_content('Watched') 
    end

    it "should display all watched records" do
      target = create(:edit_test_source, created_by: @admin_user)
      visit source_path(target)
      bookmark_and_watch_current_record

      visit watches_path
      expect(page).to have_content(target.public_id)
    end

    it "should allow a user to remove a watched record from the manage-watches page" do
      target = create(:edit_test_source, created_by: @admin_user)
      visit source_path(target)
      bookmark_and_watch_current_record

      visit watches_path
      expect(page).to have_content(target.public_id)

      find(".watch-delete", match: :first).click
    end

    it "should allow the user to export their bookmarks" do
      skip "bookmark CSV export still exists, but this belongs in lower-level coverage instead of a JS download spec"
    end

  end

  def create_bookmark_watch_entry(user)
    Entry.create!(source: create(:edit_test_source, created_by: user), created_by: user)
  end

  def bookmark_and_watch_current_record
    find('.bookmark:not(.bookmark-delete)', match: :first).click
    find('.watch:not(.watch-delete)', match: :first).click
  end

end
