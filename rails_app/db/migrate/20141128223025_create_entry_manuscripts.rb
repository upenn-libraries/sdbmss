class CreateEntryManuscripts < ActiveRecord::Migration
  def change
    create_table :entry_manuscripts do |t|
      t.references :entry, index: true
      t.references :manuscript, index: true
      t.string :relation_type

      t.timestamps
    end
  end
end
