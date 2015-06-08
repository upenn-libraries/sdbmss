class ChangeDisabledToActiveOnUsers < ActiveRecord::Migration
  def change
    remove_column :users, :disabled
    add_column :users, :active, :boolean, :default => true
  end
end
