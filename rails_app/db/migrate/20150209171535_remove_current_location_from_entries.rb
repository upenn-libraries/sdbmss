class RemoveCurrentLocationFromEntries < ActiveRecord::Migration[4.2]
  def change
    remove_column :entries, :current_location
  end
end
