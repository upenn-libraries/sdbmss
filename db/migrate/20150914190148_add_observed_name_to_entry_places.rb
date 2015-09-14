class AddObservedNameToEntryPlaces < ActiveRecord::Migration
  def change
    add_column :entry_places, :observed_name, :string
  end
end
