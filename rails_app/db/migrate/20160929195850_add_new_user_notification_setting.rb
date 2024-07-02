class AddNewUserNotificationSetting < ActiveRecord::Migration
  def change
    add_column :notification_settings, :on_new_user, :boolean, default: false
    add_column :notification_settings, :email_on_new_user, :boolean, default: false
  end
end
