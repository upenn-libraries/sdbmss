class AddRoleToEntryArtist < ActiveRecord::Migration[4.2]
  def change
    add_column :entry_artists, :role, :string
  end
end
