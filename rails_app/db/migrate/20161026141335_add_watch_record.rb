class AddWatchRecord < ActiveRecord::Migration
  def change
    create_table :watches do |t|
      t.integer :watched_id
      t.string :watched_type
      t.integer :user_id
    end
  end
end
