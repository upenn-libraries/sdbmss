class CreateEntryUses < ActiveRecord::Migration
  def change
    create_table :entry_uses do |t|
      t.references :entry, index: true
      t.string :use

    end
  end
end
