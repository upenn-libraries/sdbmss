class AddRatingObject < ActiveRecord::Migration
  def change
    create_table :ratings do |t|
      t.integer :user_id
      t.integer :ratable_id
      t.string :ratable_type
      t.string :user_level

      t.timestamps null: false
    end

  end
end
