class AddNotifiedIdToNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :notified_id, :integer
  end
end
