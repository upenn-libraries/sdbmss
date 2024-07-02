class UpdateNotificationSettingsForRealThisTime < ActiveRecord::Migration
  def change
    change_column :notification_settings, :email_on_update, :boolean, :default => true
    change_column :notification_settings, :email_on_comment, :boolean, :default => true
    change_column :notification_settings, :email_on_forum_post, :boolean, :default => true
    change_column :notification_settings, :email_on_reply, :boolean, :default => true
    change_column :notification_settings, :email_on_message, :boolean, :default => true
    change_column :notification_settings, :email_on_group, :boolean, :default => true
  end
end
