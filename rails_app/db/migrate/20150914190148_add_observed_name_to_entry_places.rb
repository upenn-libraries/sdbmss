class AddObservedNameToEntryPlaces < ActiveRecord::Migration[4.2]
  def change
    add_column :entry_places, :observed_name, :string
  end
end
