
require "rails_helper"

describe "Sign up / Edit Profile", :js => true do

  it "should allow sign up" do
    visit new_user_registration_path
    
    # show that you've read the FAQ!
    10.times do |i|
        find("label[for=faq#{i+1}]").click
    end

    fill_in 'user_username', :with => "newuser"
    fill_in 'user_email', :with => "testy@mctest.com"
    fill_in 'user_password', :with => 'somethingunguessable'
    fill_in 'user_password_confirmation', :with => 'somethingunguessable'
    click_link 'User Agreement'
    click_button 'OK'
    find("input[name=Agreement]").set true
    click_button 'Sign up'
    expect(page).to have_content 'You have signed up successfully.'

    expect(current_path).to eq("/users/edit")
  end

  it "should allow changing user profile" do
    user = User.create!(
      email: 'user@profiletest.com',
      username: 'userprofiletest',
      password: 'somethingunguessable'
    )

    visit new_user_session_path
    fill_in 'user_login', :with => user.username
    fill_in 'user_password', :with => 'somethingunguessable'
    click_button 'Log in'
    expect(page).to have_content 'Signed in successfully'

    visit edit_user_registration_path
    fill_in 'user_email', :with => "newemail@newemail.com"
    check 'user_email_is_public'
    fill_in 'user_fullname', :with => "newfullname"
    fill_in 'user_institutional_affiliation', :with => "newaffiliation"
    click_link "Account"
    fill_in 'user_password', :with => 'newpassword'
    fill_in 'user_password_confirmation', :with => 'newpassword'
    fill_in 'user_current_password', :with => 'somethingunguessable'
    fill_in 'user_bio', :with => 'newbio'
    click_button 'Update'

    expect(page).to have_content 'Your account has been updated successfully'

    visit profile_path(user.username)
    expect(page).to have_content "newemail@newemail.com"
    expect(page).to have_content "newfullname"
    expect(page).to have_content "newaffiliation"
    expect(page).to have_content "newbio"
  end

end
