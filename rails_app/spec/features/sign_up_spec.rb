
require "rails_helper"

describe "Sign up / Edit Profile", :js => true do

  def complete_faq
    # This preserves the real FAQ gate while keeping the setup readable.
    page.execute_script("$('.checkbox').prop('checked', true).trigger('change');")
  end

  it "should allow sign up" do
    visit new_user_registration_path
    unique_suffix = "#{Time.now.to_i}-#{rand(1000)}"

    complete_faq

    fill_in "user_username", with: "newuser-#{unique_suffix}"
    fill_in "user_email", with: "testy-#{unique_suffix}@mctest.com"
    fill_in "user_bio", with: "I work with manuscript data."
    all("#user_password").last.set("somethingunguessable")
    fill_in "user_password_confirmation", with: "somethingunguessable"
    click_link "User Agreement"
    click_button "OK"
    expect(page).to have_unchecked_field("Agreement", disabled: false)
    find("#check_agreement").set(true)
    expect(page).to have_button("Sign up", disabled: false)
    sleep 4.1
    click_button "Sign up"
    expect(page).to have_content "Welcome! You have signed up successfully."

    expect(current_path).to eq("/users/edit")
  end

  it "should allow changing user profile" do
    user = User.create!(
      email: 'user@profiletest.com',
      username: 'userprofiletest',
      password: 'somethingunguessable'
    )

    fast_login(user)

    visit edit_user_registration_path
    fill_in "user_email", with: "newemail@newemail.com"
    check "user_email_is_public"
    fill_in "user_fullname", with: "newfullname"
    fill_in "user_institutional_affiliation", with: "newaffiliation"
    fill_in "user_bio", with: "newbio"
    click_link "Password"
    fill_in "user_password", with: "newpassword"
    fill_in "user_password_confirmation", with: "newpassword"
    fill_in "user_current_password", with: "somethingunguessable"
    click_button "Confirm Changes"

    expect(page).to have_content "Your account has been updated successfully"

    visit profile_path(user.username)
    expect(page).to have_content "newemail@newemail.com"
    expect(page).to have_content "newfullname"
    expect(page).to have_content "newaffiliation"
    expect(page).to have_content "newbio"
  end

end
