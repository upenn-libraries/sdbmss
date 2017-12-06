require "rails_helper"

describe "Manage Comments", :js => true do

  before :all do
#    SDBMSS::ReferenceData.create_all

    @user = User.where(role: "admin").first
  end

  before :each do
    login(@user, 'somethingunguessable')
  end

  it "should add a comment to an entry" do
    visit entry_path(Entry.first)

    find("#comment").set "This is an interesting observation!"
    click_button "Post"

    expect(page).to have_content("This is an interesting observation!")

    visit comment_path(Comment.last)

    expect(page).to have_content("This is an interesting observation!")
  end

  it "should show manage comments page" do
    visit comments_path

    expect(page).to have_content("This is an interesting observation")

    find("#search_value").set "observation"
    find('#search_submit').click

    expect(page).to have_content("This is an interesting observation") 
  end

  it "should allow a user to edit their comments" do
    visit comments_path

    first('#search_results a').click

    expect(page).to have_content('interesting observation')

    first('a.comment-toggle').click

    first('form.comment-toggle #comment').set "That's ridiculous."

    click_button "Confirm"

    expect(page).to have_content("That's ridiculous.")
  end

  it "should allow a user to delete their comments" do
    visit comments_path

    first('#search_results a').click

    expect(page).to have_content('That\'s ridiculous.')

    first('a[data-method="delete"]').click
    
    expect(page).to have_content('Are you sure?')
    
    first('.btn.btn-danger.commit').click

    expect(page).to have_content('This comment has been deleted.')
    expect(page).not_to have_content('That\'s ridiculous.')
  end

  it "should properly notify the owner of the commented record" do
    skip "not yet!"
  end

end