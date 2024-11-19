class AddObservedNameToEntryArtist < ActiveRecord::Migration
  def change
    add_column :entry_artists, :observed_name, :string
  end
end
