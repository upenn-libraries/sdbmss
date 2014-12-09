class CreateEntryPlaces < ActiveRecord::Migration
  def change
    create_table :entry_places do |t|
      t.references :entry, index: true
      t.references :place, index: true
    end
  end
end
