class AddDericciNameRecords < ActiveRecord::Migration
  def change
    create_table :dericci_records do |t|
      t.string :name
      t.string :dates
      t.string :place
      t.string :url
      t.integer :cards
      t.string :size
      t.text :other_info
      t.string :senate_house
    end
  end
end
