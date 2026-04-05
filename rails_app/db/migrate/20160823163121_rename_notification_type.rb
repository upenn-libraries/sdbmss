class RenameNotificationType < ActiveRecord::Migration[4.2]
  def change
    rename_column :notifications, :type, :category
  end
end
