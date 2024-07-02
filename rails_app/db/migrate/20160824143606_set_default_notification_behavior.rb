class SetDefaultNotificationBehavior < ActiveRecord::Migration
  def change
    change_column :notifications, :active, :boolean, :default => true
  end
end
