class ChangeNotificationSettingsDefaults < ActiveRecord::Migration
  def change
    change_column :notification_settings, :email_on_all_comment, :boolean, :default => false
  end
end
