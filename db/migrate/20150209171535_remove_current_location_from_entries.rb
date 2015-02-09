class RemoveCurrentLocationFromEntries < ActiveRecord::Migration
  def change
    remove_column :entries, :current_location
  end
end
