class ChangeNotificationSettingsDefaults < ActiveRecord::Migration[4.2]
  def change
    change_column :notification_settings, :email_on_all_comment, :boolean, :default => false
  end
end
