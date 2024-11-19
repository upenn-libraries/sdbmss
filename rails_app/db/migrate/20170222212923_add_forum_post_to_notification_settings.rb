class AddForumPostToNotificationSettings < ActiveRecord::Migration
  def change
    add_column :notification_settings, :on_forum_post, :boolean, default: true
    add_column :notification_settings, :email_on_forum_post, :boolean, default: false    
  end
end
