class AddIndexToUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.index :username, unique: true
    end
  end
end
