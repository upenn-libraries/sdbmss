class AddWatchedToSettings < ActiveRecord::Migration
  def change
    add_column :notification_settings, :auto_watch, :boolean, default: true
  end
end
