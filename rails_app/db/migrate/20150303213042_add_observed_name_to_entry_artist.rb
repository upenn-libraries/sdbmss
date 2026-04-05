class AddObservedNameToEntryArtist < ActiveRecord::Migration[4.2]
  def change
    add_column :entry_artists, :observed_name, :string
  end
end
