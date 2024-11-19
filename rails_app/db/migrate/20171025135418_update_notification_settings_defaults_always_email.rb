class UpdateNotificationSettingsDefaultsAlwaysEmail < ActiveRecord::Migration
  def change
    change_column :notification_settings, :email_on_update, :boolean, :default => false
    change_column :notification_settings, :email_on_comment, :boolean, :default => false
    change_column :notification_settings, :email_on_forum_post, :boolean, :default => false
    change_column :notification_settings, :email_on_reply, :boolean, :default => false
    change_column :notification_settings, :email_on_message, :boolean, :default => false
    change_column :notification_settings, :email_on_group, :boolean, :default => false
  end
end
