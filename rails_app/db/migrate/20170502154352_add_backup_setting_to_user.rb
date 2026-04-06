class AddBackupSettingToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :backup, :boolean, :default => true
  end
end
