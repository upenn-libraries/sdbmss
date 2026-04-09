require "rails_helper"

describe "Manage Comments", :js => true do

  before :all do
#    SDBMSS::ReferenceData.create_all

    @user = User.where(role: "admin").first
  end

  before :each do
    Comment.create!(comment: "This is an interesting observation!", commentable: Entry.first, created_by: @user)
    Sunspot.commit
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

  it "should allow a user to edit their comments" do
    visit comments_path

    find('#search_results a', match: :first).click

    expect(page).to have_content('interesting observation')

    find('a.comment-toggle', match: :first).click

    find('form.comment-toggle #comment', match: :first).set "That's ridiculous."

    click_button "Confirm"

    expect(page).to have_content("That's ridiculous.")
  end

  it "should allow a user to delete their comments" do
    visit comments_path

    find('#search_results a', match: :first).click

    expect(page).to have_content('This is an interesting observation!')

    accept_data_confirm_modal_from do
      find('a[data-method="delete"]', match: :first).click
    end

    expect(page).to have_content('This comment has been deleted.')
    expect(page).not_to have_content('This is an interesting observation!')
  end

end
