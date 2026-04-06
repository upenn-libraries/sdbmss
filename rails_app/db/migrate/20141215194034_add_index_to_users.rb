class AddIndexToUsers < ActiveRecord::Migration[4.2]
  def change
    change_table :users do |t|
      t.index :username, unique: true
    end
  end
end
