require "rails_helper"

describe "User Notifications", :js => true do

  context "when user is logged in" do
    def ensure_notification_setting!(user, attrs = {})
      setting = user.notification_setting || NotificationSetting.create!(user: user)
      setting.update!(attrs) if attrs.any?
      setting
    end

    before :each do
      @user = create(:admin, password: "somethingunguessable")
      @user2 = create(:user, password: "totallysecure")
      ensure_notification_setting!(@user, on_update: true, on_comment: true, on_reply: true)
      ensure_notification_setting!(@user2, on_update: true, on_comment: true, on_reply: true)

      @source = create(:edit_test_source, created_by: @user)

      @entry1 = Entry.create!(
        source: @source,
        created_by_id: @user2.id,
        approved: true
      )

      @entry2 = Entry.create!(
        source: @source,
        created_by_id: @user2.id,
        approved: true
      )
      @user2.watches.create(watched: @entry2)
      Sunspot.commit
      login(@user, 'somethingunguessable')
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

    it "should notify a watcher when a watched record is updated" do
      initial = @user2.reload.notifications.count

      visit edit_entry_path(@entry2)
      fill_in "folios", with: 2
      find(".save-button", match: :first).click

      expect(page).to have_content('Do you have additional information about the manuscript described here?')

      expect(@user2.reload.notifications.count).to eq(initial + 1)
      expect(@user2.notifications.last.category).to eq("update")
      expect(@user2.notifications.last.notified).to eq(@entry2)
    end

    it "should notify user when one of their records is commented on" do
      initial = @user2.notifications.count
      
      visit entry_path(@entry1)
      fill_in "comment", with: "Are you getting this?"
      click_button "Post"

      expect(page).to have_content('Are you getting this?')

      expect(@user2.notifications.count).to eq(initial + 1)
      expect(@user2.notifications.last.category).to eq("comment")
    end


    it "should notify user when one of their comments is replied to" do
      comment = Comment.new(commentable: @entry1, comment: "Please respond.")
      comment.save_by(@user2)
      initial = @user2.reload.notifications.count
      initial_replies_count = Reply.count

      visit entry_path(@entry1)
      click_link "Add a reply..."
      fill_in "reply", with: "Yes."
      click_button "Add Reply"

      expect(Reply.count).to eq(initial_replies_count + 1)
      reply = Reply.order(:id).last
      expect(@user2.reload.notifications.count).to eq(initial + 1)
      expect(@user2.notifications.last.category).to eq("reply")
      expect(@user2.notifications.last.notified).to eq(reply)
    end

    it "should NOT notify user on update if notifications are disabled" do
      @user2.notification_setting.update(on_update: false)

      initial = @user2.notifications.count

      visit edit_entry_path(@entry1)
      fill_in "folios", with: 4
      find(".save-button", match: :first).click

      expect(@user2.notifications.count).to eq(initial)
    end

    it "should NOT notify user on comment if notifications are disabled" do
      @user2.notification_setting.update(on_comment: false)

      initial = @user2.notifications.count

      visit entry_path(@entry2)

      fill_in "comment", with: "You shouldn't be notified here."
      click_button "Post"

      expect(@user2.notifications.count).to eq(initial)
    end

    it "should NOT notify user on reply if reply notifications are disabled" do
      @user2.notification_setting.update(on_reply: false)

      comment = Comment.new(commentable: @entry2, comment: "An initial comment to enable replies.")
      comment.save_by(@user2)

      initial = @user2.reload.notifications.count  # capture AFTER comment notification

      visit entry_path(@entry2)
      click_link "Add a reply..."
      fill_in "reply", with: "I wasn't."
      click_button "Add Reply"

      expect(@user2.reload.notifications.count).to eq(initial)
    end

  end
end
