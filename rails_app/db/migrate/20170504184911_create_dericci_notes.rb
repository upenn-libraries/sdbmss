class CreateDericciNotes < ActiveRecord::Migration
  def change
    create_table :dericci_notes do |t|
      t.string :name
      t.string :cards
      t.string :size
      t.string :senate_house

      t.timestamps null: false
    end
  end
end
