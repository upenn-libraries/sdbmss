require "system_helper"

describe "Bookmark", :js => true do

  context "when user is logged in" do
    before :all do
      @admin_user = User.where(role: "admin").first
    end

    before :each do
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
      find('.bookmark', match: :first).click
      find('.watch', match: :first).click

      visit entry_path(Entry.last)
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
