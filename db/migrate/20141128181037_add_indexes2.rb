class AddIndexes2 < ActiveRecord::Migration
  def change
    change_table :agents do |t|
      t.index :name, unique: true
    end

  end
end
