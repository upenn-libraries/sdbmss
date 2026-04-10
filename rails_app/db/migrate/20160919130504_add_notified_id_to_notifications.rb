class AddNotifiedIdToNotifications < ActiveRecord::Migration[4.2]
  def change
    add_column :notifications, :notified_id, :integer
  end
end
