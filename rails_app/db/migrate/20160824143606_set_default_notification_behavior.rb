class SetDefaultNotificationBehavior < ActiveRecord::Migration[4.2]
  def change
    change_column :notifications, :active, :boolean, :default => true
  end
end
