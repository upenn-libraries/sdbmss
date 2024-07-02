class CreateEntryScribes < ActiveRecord::Migration
  def change
    create_table :entry_scribes do |t|
      t.references :entry, index: true
      t.references :scribe, index: true

    end
  end
end
