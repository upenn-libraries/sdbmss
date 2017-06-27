class AddBackupSettingToUser < ActiveRecord::Migration
  def change
    add_column :users, :backup, :boolean, :default => true
  end
end
