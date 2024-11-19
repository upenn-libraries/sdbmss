class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.references :entry, index: true
      t.boolean :primary, default: false
      t.text :comment
      t.integer :order
      t.string :acquire_date
      t.string :end_date
      t.decimal :price
      t.string :currency
      t.string :other_currency
      t.string :sold

    end
  end
end
