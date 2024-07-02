class AddRoleToEntryArtist < ActiveRecord::Migration
  def change
    add_column :entry_artists, :role, :string
  end
end
