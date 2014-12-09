class CreateEntryChanges < ActiveRecord::Migration
  def change
    create_table :entry_changes do |t|
      t.references :entry, index: true
      t.string :column
      t.text :changed_from
      t.text :changed_to
      t.string :change_type
      t.datetime :change_date
      t.references :changed_by, index: true

      t.timestamps
    end
  end
end
