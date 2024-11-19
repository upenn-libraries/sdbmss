class AddNewNotificationandNotificationSettingsFields < ActiveRecord::Migration
  def change
    add_column :notifications, :url, :string
    add_column :notifications, :title, :string

    add_column :notification_settings, :on_message, :boolean, default: true
    add_column :notification_settings, :email_on_message, :boolean, default: true
    add_column :notification_settings, :email_on_comment, :boolean, default: false
    add_column :notification_settings, :email_on_reply, :boolean, default: false
    add_column :notification_settings, :email_on_update, :boolean, default: false
  end
end
