require "rails_helper"

describe "User Notifications", :js => true do
  let_it_be(:actor)     { create(:admin, password: "somethingunguessable") }
  let_it_be(:recipient) { create(:user, password: "totallysecure") }
  let_it_be(:source)    { create(:edit_test_source, created_by: actor) }
  let_it_be(:recipient_entry, reload: true) do
    Entry.create!(
      source: source,
      created_by_id: recipient.id,
      approved: true
    )
  end
  let_it_be(:watched_entry, reload: true) do
    Entry.create!(
      source: source,
      created_by_id: recipient.id,
      approved: true
    )
  end
  let_it_be(:actor_notification_setting) do
    actor.notification_setting.tap do |setting|
      setting.update!(on_update: true, on_comment: true, on_reply: true)
    end
  end
  let_it_be(:recipient_notification_setting) do
    recipient.notification_setting.tap do |setting|
      setting.update!(on_update: true, on_comment: true, on_reply: true)
    end
  end

  context "when user is logged in" do
    before :each do
      recipient.watches.create!(watched: watched_entry)
      Sunspot.commit
      fast_login(actor)
    end

    it "should be associated with a given user" do
      expect(actor.notifications).not_to be_nil
    end

    it "should have appropriate setting" do
      expect(actor.notification_setting).not_to be_nil
      expect(actor.notification_setting.on_update).to be_truthy
      expect(actor.notification_setting.on_comment).to be_truthy
      expect(actor.notification_setting.on_reply).to be_truthy
    end

    it "should notify a watcher when a watched record is updated" do
      initial = recipient.reload.notifications.count

      visit edit_entry_path(watched_entry)
      fill_in "folios", with: 2
      find(".save-button", match: :first).click

      expect(page).to have_content('Do you have additional information about the manuscript described here?')

      expect(recipient.reload.notifications.count).to eq(initial + 1)
      expect(recipient.notifications.last.category).to eq("update")
      expect(recipient.notifications.last.notified).to eq(watched_entry)
    end

    it "should notify user when one of their records is commented on" do
      initial = recipient.notifications.count
      
      visit entry_path(recipient_entry)
      fill_in "comment", with: "Are you getting this?"
      click_button "Post"

      expect(page).to have_content('Are you getting this?')

      expect(recipient.notifications.count).to eq(initial + 1)
      expect(recipient.notifications.last.category).to eq("comment")
    end


    it "should notify user when one of their comments is replied to" do
      comment = Comment.new(commentable: recipient_entry, comment: "Please respond.")
      comment.save_by(recipient)
      initial = recipient.reload.notifications.count
      initial_replies_count = Reply.count

      visit entry_path(recipient_entry)
      click_link "Add a reply..."
      fill_in "reply", with: "Yes."
      click_button "Add Reply"

      expect(Reply.count).to eq(initial_replies_count + 1)
      reply = Reply.order(:id).last
      expect(recipient.reload.notifications.count).to eq(initial + 1)
      expect(recipient.notifications.last.category).to eq("reply")
      expect(recipient.notifications.last.notified).to eq(reply)
    end

    it "should NOT notify user on update if notifications are disabled" do
      recipient.notification_setting.update(on_update: false)

      initial = recipient.notifications.count

      visit edit_entry_path(recipient_entry)
      fill_in "folios", with: 4
      find(".save-button", match: :first).click

      expect(recipient.notifications.count).to eq(initial)
    end

    it "should NOT notify user on comment if notifications are disabled" do
      recipient.notification_setting.update(on_comment: false)

      initial = recipient.notifications.count

      visit entry_path(recipient_entry)

      fill_in "comment", with: "You shouldn't be notified here."
      click_button "Post"

      expect(recipient.notifications.count).to eq(initial)
    end

    it "should NOT notify user on reply if reply notifications are disabled" do
      recipient.notification_setting.update(on_reply: false)

      comment = Comment.new(commentable: recipient_entry, comment: "An initial comment to enable replies.")
      comment.save_by(recipient)

      initial = recipient.reload.notifications.count  # capture AFTER comment notification

      visit entry_path(recipient_entry)
      click_link "Add a reply..."
      fill_in "reply", with: "I wasn't."
      click_button "Add Reply"

      expect(recipient.reload.notifications.count).to eq(initial)
    end

  end
end
