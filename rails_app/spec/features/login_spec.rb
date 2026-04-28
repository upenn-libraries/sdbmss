require "rails_helper"

describe "Login", :js => true do

  let(:password)      { "somethingreallylong" }
  let(:contributor)   { create(:user, role: "contributor", password: password) }
  let(:admin_user)    { create(:admin, password: password) }
  let(:inactive_user) { create(:user, active: false, password: password) }

  # ---------------------------------------------------------------------------
  # Successful login
  # ---------------------------------------------------------------------------
  describe "with valid credentials" do
    it "signs the user in and shows success flash" do
      visit root_path
      fill_in "user_login",    with: contributor.username
      fill_in "user_password", with: password
      click_button "Log in"

      expect(page).to have_content("Signed in successfully")
    end

    it "redirects to the contributions dashboard after sign-in" do
      login(contributor, password)
      expect(current_path).to eq(dashboard_contributions_path)
    end
  end

  # ---------------------------------------------------------------------------
  # Failed login — wrong password
  # ---------------------------------------------------------------------------
  describe "with an incorrect password" do
    it "rejects the login and shows an error" do
      visit root_path
      fill_in "user_login",    with: contributor.username
      fill_in "user_password", with: "wrongpassword"
      click_button "Log in"

      expect(page).to have_content("Invalid")
      expect(current_path).not_to eq(dashboard_contributions_path)
    end
  end

  # ---------------------------------------------------------------------------
  # Failed login — inactive account
  # ---------------------------------------------------------------------------
  describe "with an inactive account" do
    it "shows the inactive-account message instead of signing in" do
      visit root_path
      fill_in "user_login",    with: inactive_user.username
      fill_in "user_password", with: password
      click_button "Log in"

      expect(page).to have_content("New SDBM accounts are inactive by default.")
      expect(current_path).not_to eq(dashboard_contributions_path)
    end
  end

  # ---------------------------------------------------------------------------
  # login_as — admin impersonates another user
  # ---------------------------------------------------------------------------
  describe "login_as (admin impersonation)" do
    context "when current user is an admin" do
      before { login(admin_user, password) }

      it "switches session to the target user and lands on dashboard" do
        visit login_as_path(username: contributor.username)
        expect(current_path).to eq(dashboard_contributions_path)
      end

      it "shows the impersonated user's identity on the page" do
        visit login_as_path(username: contributor.username)
        # Dashboard or nav should show the impersonated user's username
        expect(page).to have_content(contributor.username)
      end
    end

    context "when current user is not an admin" do
      before { login(contributor, password) }

      it "returns a forbidden response" do
        visit login_as_path(username: admin_user.username)
        # Non-admin gets 403; Capybara renders the response body
        expect(page).not_to have_current_path(dashboard_contributions_path)
        expect(page.status_code).to eq(403)
      end
    end
  end
end
