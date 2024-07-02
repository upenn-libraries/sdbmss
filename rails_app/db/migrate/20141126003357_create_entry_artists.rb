class CreateEntryArtists < ActiveRecord::Migration
  def change
    create_table :entry_artists do |t|
      t.references :entry, index: true
      t.references :artist, index: true
    end
  end
end
