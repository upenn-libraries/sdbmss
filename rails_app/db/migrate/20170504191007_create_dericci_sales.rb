class CreateDericciSales < ActiveRecord::Migration
  def change
    create_table :dericci_sales do |t|
      t.string :name
      t.string :cards
      t.string :size
      t.string :senate_house
      t.string :link

      t.timestamps null: false
    end
  end
end
