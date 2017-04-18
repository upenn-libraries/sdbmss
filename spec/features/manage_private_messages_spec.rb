
require 'json'
require "rails_helper"

# There's JS on most of these pages. Not all features use JS, but
# there's no good reason NOT to use the js driver, so we do.
describe "Manage Private Messages", :js => true do

  before :all do
    @user = User.where(role: "admin").first
    @user2 = User.where(role: "contributor").first
  end

  before :each do
      login(@user, 'somethingunguessable')
  end

  after :each do
    page.reset!
  end

  it "should prevent a 'guest' user from accessing messaging" do    
    visit "/users/sign_out"
    expect(page).to have_content("Login")

    visit private_messages_path
    expect(page).to have_content("You need to sign in or sign up before continuing.")
  end

  it "should display an intelligable empty inbox" do
    visit private_messages_path
    expect(page).to have_content('You do not have any private messages.')
  end

  it "should allow a user to send a new private message" do
    visit new_private_message_path(user_id: [@user2.id])
    
    expect(page).to have_content("New Private Message")

    fill_in "title", with: "Welcome!"
    fill_in "message", with: "This is a welcome message."

    click_button "Send Message"

    expect(page).to have_content("Welcome!")
    expect(page).to have_content("This is a welcome message.")
    expect(page).to have_content(@user.username)
    expect(page).to have_content(@user2.username)
  
    expect(PrivateMessage.count).to eq(1)

    visit private_messages_path(sent_by: true)
    expect(page).to have_content("Welcome!")
    expect(page).to have_content(@user.username)
    expect(page).to have_content(@user2.username)
  end
end
