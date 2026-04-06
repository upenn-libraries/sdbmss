class ChangeDisabledToActiveOnUsers < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :disabled
    add_column :users, :active, :boolean, :default => true
  end
end
