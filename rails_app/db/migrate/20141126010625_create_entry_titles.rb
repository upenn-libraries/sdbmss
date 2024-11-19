class CreateEntryTitles < ActiveRecord::Migration
  def change
    create_table :entry_titles do |t|
      t.references :entry, index: true
      t.string :title, limit: 2048
      t.string :common_title, limit: 2048
    end
  end
end
