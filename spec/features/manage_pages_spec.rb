
require 'json'
require "rails_helper"

# There's JS on most of these pages. Not all features use JS, but
# there's no good reason NOT to use the js driver, so we do.
describe "Manage Pages", :js => true do

  before :all do
    @user = User.create!(
      email: 'testuser@test.com',
      username: 'adminuser',
      password: 'somethingunguessable',
      role: 'admin'
    )
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

  it "should prevent a user from managing pages when not logged in" do
    visit "/users/sign_out"
    expect(page).to have_content("Login")

    visit pages_path
    expect(page).to have_content("You tried to access a page or perform an action for which you don't have permission.")
  end

  it "should only allow an admin to manage pages" do
    @user.update!(role: "contributor")
    visit pages_path
    expect(page).to have_content("You tried to access a page or perform an action for which you don't have permission.")

    @user.update!(role: "editor")
    visit pages_path
    expect(page).to have_content("You tried to access a page or perform an action for which you don't have permission.")

    @user.update!(role: "super_editor")
    visit pages_path
    expect(page).to have_content("You tried to access a page or perform an action for which you don't have permission.")

    @user.update!(role: "admin")
    visit pages_path
    expect(page).to have_content("Static Pages & Tooltips")
  end

  it "should allow an admin to create a new page" do
    visit pages_path
    click_link("Click Here To Add New Page")

    expect(page).to have_content('Create New Page')

    File.open("/tmp/new_page.html", 'wb') do |file|
      file.write("No one can reign innocently.")
    end

    attach_file("page[filename]", "/tmp/new_page.html")
    fill_in "page[name]", with: "New Page"
    select('about', :from => 'page[category]')
    click_button 'Upload File'

    expect(page).to have_content('New Page')
    expect(page).to have_content('new_page.html')
    click_link 'New Page'
    expect(page).to have_content("No one can reign innocently.")    
  end

  it "should allow an admin to create a new tooltip" do
    visit pages_path
    click_link("Click Here To Add New Page")

    expect(page).to have_content('Create New Page')

    File.open("/tmp/new_tooltip.html", 'wb') do |file|
      file.write("Property is theft.")
    end

    attach_file("page[filename]", "/tmp/new_tooltip.html")
    fill_in "page[name]", with: "New Tooltip"
    select('tooltip', :from => 'page[category]')
    click_button 'Upload File'

    expect(page).to have_content('New Tooltip')
    expect(page).to have_content('new_tooltip.html')
    click_link 'New Tooltip'
    expect(page).to have_content("Property is theft.")  
  end

  it "should allow a user to edit a page" do
    visit edit_page_path(Page.last.name)
    
    fill_in "contents", with: "The Philosophy of Poverty"
    fill_in "page[name]", with: "Updated Tooltip"

    click_button "Save Changes"
    expect(page).to have_content('Updated Tooltip')
  end

  it "should allow a user to delete a page" do
    skip "because poltergeist can't handle a modal popup"
    n = Page.count
    visit pages_path  
    first("a[data-method='delete']").click
    expect(page).to have_content("Confirm")
    click_button("Confirm")

    expect(page).to have_content("successfully deleted.")
    expect(Page.count).to eq(n - 1)
  end

end
