class CreateEntryUses < ActiveRecord::Migration[4.2]
  def change
    create_table :entry_uses do |t|
      t.references :entry, index: true
      t.string :use

    end
  end
end
