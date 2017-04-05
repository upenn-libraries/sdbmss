require "rails_helper"

describe "User Notifications", :js => true do
  
  before :all do
    @user = User.where(role: "admin").first
    @user2 = User.create!(
      email: 'other@test.com',
      username: 'other',
      password: 'totallysecure'
    )
    @user.notification_setting.update!(on_update: true, on_comment: true, on_reply: true)
    @user2.notification_setting.update!(on_update: true, on_comment: true, on_reply: true)

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
    @user2.watches.create(watched: @entry2)
  end

  context "when user is logged in" do
  
    before :each do
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

    it "should notify user when one of their records is updated" do
      skip "the notification is being created but is delayed for some reason"

      initial = @user2.notifications.count

      visit edit_entry_path(@entry1)
      fill_in "folios", with: 2
      first(".save-button").click

      expect(page).to have_content('Do you have additional information about the manuscript described here?')

      expect(@user2.notifications.count).to eq(initial + 1)
      expect(@user2.notifications.last.category).to eq("update")
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
      skip "this is a reply on a comment by the same user; so no notification"
      initial = @user2.notifications.count
      initial_replies_count = Reply.count

      visit entry_path(@entry1)
      click_link "Add a reply..."
      fill_in "reply", with: "Yes."
      click_button "Add Reply"

      expect(Reply.count).to eq(initial_replies_count + 1)
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
      click_button "Post"

      expect(@user2.notifications.count).to eq(initial)
    end

    it "should NOT notify user on comment if notifications are disabled" do
      @user2.notification_setting.update(on_reply: false)

      initial = @user2.notifications.count

      visit entry_path(@entry2)

      click_link "Add a reply..."
      fill_in "reply", with: "I wasn't."
      click_button "Add Reply"

      expect(@user2.notifications.count).to eq(initial)
    end

  end
end