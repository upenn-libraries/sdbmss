require "rails_helper"

describe "User Notifications", :js => true do
  
  before :all do
    User.where(username: 'testuser').delete_all
    @user = User.create!(
      email: 'testuser@test.com',
      username: 'testuser',
      password: 'somethingunguessable',
      role: 'admin'
    )
    @user2 = User.create!(
      email: 'other@test.com',
      username: 'other',
      password: 'totallysecure'
    )
    @user.can_notify("update")
    @user.notification_setting.update(on_reply: true)
    @user2.can_notify("update")
    @user2.notification_setting.update(on_reply: true)

    source = Source.create!(
      title: "a new source",
      source_type: SourceType.collection_catalog,
    )

    #create some records
    @entry1 = Entry.create!(
      source: Source.first,
      created_by_id: @user2.id,
      approved: true
    )

    @entry2 = Entry.create!(
      source: Source.first,
      created_by_id: @user2.id,
      approved: true
    )
  end

  context "when user is logged in" do
  
    before :each do
      visit new_user_session_path
      fill_in 'user_login', :with => @user.username
      fill_in 'user_password', :with => 'somethingunguessable'
      click_button 'Log in'
      expect(page).to have_content 'Signed in successfully'
    end

    it "should be associated with a given user" do
      expect(@user.notifications).not_to be_nil
    end

    it "should have appropriate setting" do
      expect(@user.notification_setting).not_to be_nil
      expect(@user.notification_setting.on_update).to be_truthy
      expect(@user.notification_setting.on_comment).to be_truthy
      expect(@user.notification_setting.on_reply).to be_truthy
    end

    it "should allow users to modify their notification setting" do
      visit edit_notification_setting_path
      expect(page).to have_content("Notification setting")
    end

    it "should notify user when one of their records is updated" do
      
      initial = @user2.notifications.count

      visit edit_entry_path(@entry1)
      fill_in "folios", with: 2
      first(".save-button").click

      sleep 1
      expect(@user2.notifications.count).to eq(initial + 1)
      expect(@user2.notifications.last.category).to eq("update")
    end

    it "should notify user when one of their records is commented on" do
      initial = @user2.notifications.count
      
      visit entry_path(@entry1)
      fill_in "comment", with: "Are you getting this?"
      click_button "Add Comment"

      expect(@user2.notifications.count).to eq(initial + 1)
      expect(@user2.notifications.last.category).to eq("comment")
    end


    it "should notify user when one of their comments is replied to" do
      initial = @user2.notifications.count

      visit entry_path(@entry1)
      fill_in "reply", with: "Yes."
      click_button "Add Reply"

      expect(@user2.notifications.count).to eq(initial + 1)
      expect(@user2.notifications.last.category).to eq("reply")
    end

    it "should NOT notify user on update if notifications are disabled" do
      @user2.notification_setting.update(on_update: false)

      initial = @user2.notifications.count

      visit edit_entry_path(@entry1)
      fill_in "folios", with: 4
      first(".save-button").click

      expect(@user2.notifications.count).to eq(initial)
    end

    it "should NOT notify user on comment if notifications are disabled" do
      @user2.notification_setting.update(on_comment: false)

      initial = @user2.notifications.count

      visit entry_path(@entry2)

      fill_in "comment", with: "You shouldn't be notified here."
      click_button "Add Comment"

      expect(@user2.notifications.count).to eq(initial)
    end

    it "should NOT notify user on comment if notifications are disabled" do
      @user2.notification_setting.update(on_reply: false)

      initial = @user2.notifications.count

      visit entry_path(@entry2)

      fill_in "reply", with: "I wasn't."
      click_button "Add Reply"

      expect(@user2.notifications.count).to eq(initial)
    end

  end
end