class CreateEntryLanguages < ActiveRecord::Migration
  def change
    create_table :entry_languages do |t|
      t.references :entry, index: true
      t.references :language, index: true

    end
  end
end
