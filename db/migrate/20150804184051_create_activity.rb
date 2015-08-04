class CreateActivity < ActiveRecord::Migration
  def change
    create_table :activities do |t|
      t.string :item_type, limit: 255, null: false
      t.integer :item_id
      t.string :event, limit: 255, null: false
      t.integer :user_id
      t.datetime :created_at
    end
  end
end
