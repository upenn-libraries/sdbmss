class ChangeNameOnLanguages < ActiveRecord::Migration
  def change
    change_table :languages do |t|
      t.index :name, unique: true
    end
  end
end
