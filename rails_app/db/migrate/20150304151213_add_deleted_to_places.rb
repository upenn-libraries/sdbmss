class AddDeletedToPlaces < ActiveRecord::Migration
  def change
    add_column :places, :deleted, :boolean, :default => false
  end
end
