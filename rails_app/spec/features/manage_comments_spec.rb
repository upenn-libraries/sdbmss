require "rails_helper"

describe "Manage Comments", :js => true do
  let(:admin_user) { create(:admin) }

  before :each do
    @entry = create(:edit_test_entry, source: create(:edit_test_source, created_by: admin_user), created_by: admin_user, approved: true)
    SampleIndexer.index_records!(@entry)
    Comment.create!(comment: "This is an interesting observation!", commentable: @entry, created_by: admin_user)
    Sunspot.commit
    fast_login(admin_user)
  end

  it "should add a comment to an entry", :solr do
    visit entry_path(@entry)

    find("#comment").set "This is an interesting observation!"
    click_button "Post"

    expect(page).to have_content("This is an interesting observation!")

    visit comment_path(Comment.last)

    expect(page).to have_content("This is an interesting observation!")
  end

  it "should allow a user to edit their comments", :solr do
    visit comments_path

    find('#search_results a', match: :first).click

    expect(page).to have_content('interesting observation')

    find('a.comment-toggle', match: :first).click

    find('form.comment-toggle #comment', match: :first).set "That's ridiculous."

    click_button "Confirm"

    expect(page).to have_content("That's ridiculous.")
  end

  it "should allow a user to delete their comments", :solr do
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
