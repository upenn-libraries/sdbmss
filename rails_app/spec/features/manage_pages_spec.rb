
require 'json'
require "rails_helper"

# There's JS on most of these pages. Not all features use JS, but
# there's no good reason NOT to use the js driver, so we do.
describe "Manage Pages", :js => true do
  let(:admin_user) { create(:admin) }

  before :each do
      login(admin_user, 'somethingreallylong')
  end

  after :each do
    page.reset!
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
    filename = "test_edit_tooltip_#{Time.now.to_i}_#{rand(1000)}.html"
    tooltip_page = Page.create!(name: "Test Edit Tooltip", filename: filename, category: "tooltip")
    File.open(Rails.root.join("public", tooltip_page.location, tooltip_page.filename), "wb") do |file|
      file.write("Original tooltip text")
    end
    visit edit_page_path(tooltip_page.name)
    fill_in "page[name]", with: "Updated Tooltip"
    click_button "Save Changes"
    expect(page).to have_content('Updated Tooltip')
  end

  it "should allow a user to delete a page" do
    filename = "test_delete_tooltip_#{Time.now.to_i}_#{rand(1000)}.html"
    page_to_delete = Page.create!(name: "Test Delete Tooltip", filename: filename, category: "tooltip")
    File.open(Rails.root.join("public", page_to_delete.location, page_to_delete.filename), "wb") do |file|
      file.write("Delete me")
    end
    n = Page.count
    visit pages_path  
    accept_data_confirm_modal_from do
      find("a[href='#{page_path(page_to_delete.name)}'][data-method='delete']", match: :first).click
    end

    expect(page).to have_content("successfully deleted.")
    expect(Page.count).to eq(n - 1)
  end

end
