
require "rails_helper"

describe "Sign up / Edit Profile", :js => true do

  it "should allow sign up", :known_failure do
    visit new_user_registration_path
    unique_suffix = Time.now.to_i.to_s
    
    # show that you've read the FAQ!
    page.execute_script("$('.checkbox').prop('checked', true).trigger('change');")

    fill_in 'user_username', :with => "newuser-#{unique_suffix}"
    fill_in 'user_email', :with => "testy-#{unique_suffix}@mctest.com"
    fill_in 'user_bio', :with => 'I work with manuscript data.'
    all('#user_password').last.set 'somethingunguessable'
    fill_in 'user_password_confirmation', :with => 'somethingunguessable'
    click_link 'User Agreement'
    click_button 'OK'
    find("input[name=Agreement]").set true
    sleep 12
    click_button 'Sign up'
    expect(page).to have_content 'Welcome! You have signed up successfully.'

    expect(current_path).to eq("/users/edit")
  end

  it "should allow changing user profile" do
    user = User.create!(
      email: 'user@profiletest.com',
      username: 'userprofiletest',
      password: 'somethingunguessable'
    )

    login(user, 'somethingunguessable')

    visit edit_user_registration_path
    fill_in 'user_email', :with => "newemail@newemail.com"
    check 'user_email_is_public'
    fill_in 'user_fullname', :with => "newfullname"
    fill_in 'user_institutional_affiliation', :with => "newaffiliation"
    fill_in 'user_bio', :with => 'newbio'
    click_link "Password"
    fill_in 'user_password', :with => 'newpassword'
    fill_in 'user_password_confirmation', :with => 'newpassword'
    fill_in 'user_current_password', :with => 'somethingunguessable'
    click_button 'Confirm Changes'

    expect(page).to have_content 'Your account has been updated successfully'

    visit profile_path(user.username)
    expect(page).to have_content "newemail@newemail.com"
    expect(page).to have_content "newfullname"
    expect(page).to have_content "newaffiliation"
    expect(page).to have_content "newbio"
  end

end
