class AddDeletedToPlaces < ActiveRecord::Migration[4.2]
  def change
    add_column :places, :deleted, :boolean, :default => false
  end
end
