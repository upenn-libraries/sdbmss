require "rails_helper"

describe "Bookmark", :js => true do

  context "when user is logged in" do
    before :each do
      @admin_user = User.where(role: "admin").first
      Bookmark.create!(user_id: @admin_user.id, user_type: 'User', document_id: Entry.last.id.to_s, document_type: 'Entry', tags: 'new tag')
      login(@admin_user, 'somethingunguessable')
    end

    it "should allow a user to bookmark an entry from a public search" do
      visit root_path
      click_button "Search"

      expect(page).to have_content(Entry.last.public_id)
      find('.bookmark', match: :first).click

      visit bookmarks_path
      expect(page).to have_content("of this type")
      expect(page).to have_content(Entry.last.public_id)
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
      expect(page).to have_content(Entry.last.public_id)
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
      expect(page).to have_content(Entry.last.public_id)
      expect(page).to have_content 'new tag'
      find('.remove-bookmark-tag-confirm', match: :first).click
      expect(page).not_to have_content 'new tag'
      find('.remove-bookmark', match: :first).click
      expect(page).to have_content "un-bookmarked"
      visit bookmarks_path
      expect(page).not_to have_content(Entry.last.public_id)
    end

    it "should bookmark/watch and remove for Entries" do
      visit entries_path
      # Derive the target entry from the class of the first visible bookmark button
      # Bookmark buttons have class "Bookmark_Entry_<id>"
      bookmark_link = find('.bookmark:not(.bookmark-delete)', match: :first)
      entry_id = bookmark_link[:class].match(/Bookmark_Entry_(\d+)/)[1].to_i
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
      visit names_path
      find('.DTFC_LeftWrapper .bookmark', match: :first).click
      find('.DTFC_LeftWrapper .watch', match: :first).click

      visit name_path(Name.last)
      expect(page).to have_content('Bookmarked')
      expect(page).to have_content('Watched')

      find('.bookmark-delete', match: :first).click
      find('.watch-delete', match: :first).click

      expect(page).not_to have_content('Bookmarked')
      expect("#control-panel").not_to have_content('Watched')
    end

    it "should bookmark/watch and remove for Sources" do
      visit sources_path
      find('.DTFC_LeftWrapper .bookmark', match: :first).click
      find('.DTFC_LeftWrapper .watch', match: :first).click

      visit source_path(Source.last)
      expect(page).to have_content('Bookmarked')
      expect(page).to have_content('Watched')

      find('.bookmark-delete', match: :first).click
      find('.watch-delete', match: :first).click

      expect(page).not_to have_content('Bookmarked')
      expect("#control-panel").not_to have_content('Watched') 
    end

    it "should bookmark/watch and remove for Manuscript Records" do
      visit manuscripts_path
      find('.bookmark', match: :first).click
      find('.watch', match: :first).click

      visit manuscript_path(Manuscript.last)
      expect(page).to have_content('Bookmarked')
      expect(page).to have_content('Watched')

      find('.bookmark-delete', match: :first).click
      find('.watch-delete', match: :first).click

      expect(page).not_to have_content('Bookmarked')
      expect("#control-panel").not_to have_content('Watched')
    end

    it "should bookmark/watch and remove for Dericci Records" do
      visit dericci_records_path
      expect(page).to have_content(DericciRecord.order("name ASC").first.name)
      find('.bookmark', match: :first).click
      find('.watch', match: :first).click

      visit dericci_record_path(DericciRecord.order("name ASC").first)
      expect(page).to have_content('Bookmarked')
      expect(page).to have_content('Watched')

      find('.bookmark-delete', match: :first).click
      find('.watch-delete', match: :first).click

      expect(page).not_to have_content('Bookmarked')
      expect("#control-panel").not_to have_content('Watched') 
    end

    it "should display all watched records" do
      visit sources_path
      find('.DTFC_LeftWrapper .bookmark', match: :first).click
      find('.DTFC_LeftWrapper .watch', match: :first).click

      visit watches_path
      expect(page).to have_content(Source.last.public_id)
    end

    it "should allow a user to remove a watched record from the manage-watches page" do
      visit sources_path
      find('.DTFC_LeftWrapper .bookmark', match: :first).click
      find('.DTFC_LeftWrapper .watch', match: :first).click

      visit watches_path
      expect(page).to have_content(Source.last.public_id)

      find(".watch-delete", match: :first).click
    end

    it "should allow the user to export their bookmarks" do
      skip "Is this still/should this still be an option?"
    end

  end
end