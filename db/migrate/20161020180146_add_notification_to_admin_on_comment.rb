class AddNotificationToAdminOnComment < ActiveRecord::Migration
  def change
    add_column :notification_settings, :on_all_comment, :boolean, default: true
    add_column :notification_settings, :email_on_all_comment, :boolean, default: true
  end
end
