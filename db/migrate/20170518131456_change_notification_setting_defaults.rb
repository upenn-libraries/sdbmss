class ChangeNotificationSettingDefaults < ActiveRecord::Migration
  def change
    change_column_default :notification_settings, :on_update, true
    change_column_default :notification_settings, :on_comment, true
    change_column_default :notification_settings, :on_reply, true
  end
end
