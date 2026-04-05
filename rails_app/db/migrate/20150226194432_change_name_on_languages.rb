class ChangeNameOnLanguages < ActiveRecord::Migration[4.2]
  def change
    change_table :languages do |t|
      t.index :name, unique: true
    end
  end
end
