class AddGroupActionsToNotificationSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :notification_settings, :on_group, :boolean, default: true
    add_column :notification_settings, :email_on_group, :boolean, default: false
  end
end
