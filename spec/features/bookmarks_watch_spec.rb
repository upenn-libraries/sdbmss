require "rails_helper"

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
      first('.bookmark').click

      visit bookmarks_path
      expect(page).to have_content("of this type")
      expect(page).to have_content(Entry.last.public_id)
    end

    it "should allow the user to add tags to their bookmark" do
      visit bookmarks_path

      first('.btn-add-tag').click
      expect(page).to have_content('Tag:')
      first('.new-bookmark-tag').set "new tag"
      first('.add-bookmark-tag-confirm').click

      expect(page).to have_content('new tag')
      first('input[name="tag-search"]').set "new tag"
      first('.bookmark-search').click
      expect(page).to have_content(Entry.last.public_id)
    end

    it "should not add a tag that is already present" do
      visit bookmarks_path

      first('.btn-add-tag').click
      expect(page).to have_content('Tag:')
      first('.new-bookmark-tag').set "new tag"
      first('.add-bookmark-tag-confirm').click

      expect(page).to have_content('new tag')
    end

    it "should remove a tag and bookmark as desired" do
      expect(Bookmark.count).to eq(1)
      visit bookmarks_path
      expect(page).to have_content(Entry.last.public_id)
      expect(page).to have_content 'new tag'
      first('.remove-bookmark-tag-confirm').click
      expect(page).not_to have_content 'new tag'
      first('.remove-bookmark').click
      expect(page).to have_content "un-bookmarked"
      visit bookmarks_path
      expect(page).not_to have_content(Entry.last.public_id)
    end

    it "should bookmark/watch and remove for Entries" do
      visit entries_path
      first('.bookmark').click
      first('.watch').click

      visit entry_path(Entry.last)
      expect(page).to have_content('Bookmarked')
      expect(page).to have_content('Watched')

      first('.bookmark-delete').click
      first('.watch-delete').click

      expect(page).not_to have_content('Bookmarked')
      expect("#control-panel").not_to have_content('Watched')

    end

    it "should bookmark/watch and remove for Names" do
      visit names_path
      first('.DTFC_LeftWrapper .bookmark').click
      first('.DTFC_LeftWrapper .watch').click

      visit name_path(Name.last)
      expect(page).to have_content('Bookmarked')
      expect(page).to have_content('Watched')

      first('.bookmark-delete').click
      first('.watch-delete').click

      expect(page).not_to have_content('Bookmarked')
      expect("#control-panel").not_to have_content('Watched')
    end

    it "should bookmark/watch and remove for Sources" do
      visit sources_path
      first('.DTFC_LeftWrapper .bookmark').click
      first('.DTFC_LeftWrapper .watch').click

      visit source_path(Source.last)
      expect(page).to have_content('Bookmarked')
      expect(page).to have_content('Watched')

      first('.bookmark-delete').click
      first('.watch-delete').click

      expect(page).not_to have_content('Bookmarked')
      expect("#control-panel").not_to have_content('Watched') 
    end

    it "should display all watched records" do
      visit sources_path
      first('.DTFC_LeftWrapper .bookmark').click
      first('.DTFC_LeftWrapper .watch').click

      visit watches_path
      expect(page).to have_content(Source.last.public_id)
    end

    it "should allow a user to remove a watched record from the manage-watches page" do
      visit sources_path
      first('.DTFC_LeftWrapper .bookmark').click
      first('.DTFC_LeftWrapper .watch').click

      visit watches_path
      expect(page).to have_content(Source.last.public_id)

      first(".watch-delete").click
    end

    it "should allow the user to export their bookmarks" do
      skip "Is this still/should this still be an option?"
    end

  end
end