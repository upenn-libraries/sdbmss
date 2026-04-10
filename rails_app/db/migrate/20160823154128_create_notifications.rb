class CreateNotifications < ActiveRecord::Migration[4.2]
  def change
    create_table :notifications do |t|
      t.string :message
      t.string :type
      t.boolean :active
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
