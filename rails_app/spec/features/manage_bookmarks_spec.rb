
require 'json'
require "system_helper"

# There's JS on most of these pages. Not all features use JS, but
# there's no good reason NOT to use the js driver, so we do.
# 
# bookmarks need to be reworked. no more angular, you know>
# 
=begin
describe "Manage Bookmarks", :js => true do

  before :all do
#    SDBMSS::ReferenceData.create_all

    @user = User.where(role: "admin").first
  end

  before :each do
    visit root_path
    fill_in 'user_login', :with => @user.username
    fill_in 'user_password', :with => 'somethingunguessable'
    click_button 'Log in'
    expect(page).to have_content 'Signed in successfully'
  end

  after :each do
    page.reset!
  end

  it "should prevent a user from bookmarking when not logged in" do
    visit "/users/sign_out"
    expect(page).to have_content("Login")

    visit bookmarks_path
    expect(page).to have_content('You need to sign in or sign up before continuing.')

    visit root_path
    click_button "Search"

    expect(page).not_to have_css('.bookmark')
  end

  it "should display an empty bookmarks list" do
    visit bookmarks_path

    expect(page).to have_content "No Entry Records to display."
    expect(page).to have_content "No Source Records to display."
    expect(page).to have_content "No Name Records to display."
    expect(page).to have_content "No Manuscript Records to display."
  end

  it "should allow a user to bookmark any entry from the catalog search" do
    visit root_path

    click_button "Search"

    expect(page).to have_content(Entry.last.public_id)
    expect(page).to have_css('.bookmark')
    # generates AJAX error, but passes anyway?
    find('.bookmark', match: :first).trigger('click')

    visit bookmarks_path
    sleep 60
    expect(page).to have_content(Entry.last.public_id)
  end

  it "should allow a user to tag their bookmark" do
    visit bookmarks_path

    click_link 'Add Tag'
    find('.add-bookmark-tag input').set 'New Tag'

    find('.add-bookmark-tag-confirm', match: :first).click
    expect(page).to have_content('New Tag')

    fill_in "tag-search", with: "Wrong Tag"
    find('.bookmark-search', match: :first).click
    expect(page).not_to have_content(Bookmark.last.document.public_id)

    fill_in "tag-search", with: "New Tag"
    find('.bookmark-search', match: :first).click
    expect(page).to have_content(Bookmark.last.document.public_id)
  end

  it "should allow a user to un-tag their bookmark" do
    visit bookmarks_path

    expect(page).to have_content('New Tag')
    find('.remove-bookmark-tag-confirm', match: :first).click

    expect(page).not_to have_content('New Tag')
  end

  it "should allow a user to export their bookmarks" do
    skip "Asynch CSV export method untested at the moment"
  end

  it "should allow a user to delete a bookmark" do
    visit bookmarks_path
    id = Bookmark.last.document.public_id
    expect(page).to have_content(id)

    find('.remove-bookmark', match: :first).click

    expect(page).not_to have_content(id)
  end

end
=end
