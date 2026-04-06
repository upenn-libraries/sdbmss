class AddWatchedToSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :notification_settings, :auto_watch, :boolean, default: true
  end
end
