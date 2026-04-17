class AddDisabledFlagToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :disabled, :boolean, :default => false
  end
end
