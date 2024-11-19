class AddFlagsToEntries < ActiveRecord::Migration
  def change
    add_column :entries, :deprecated, :boolean, :default => false
    add_reference :entries, :superceded_by, :index => true
    add_foreign_key "entries", "entries", column: "superceded_by_id"
  end
end
