class AddIndexes < ActiveRecord::Migration
  def change
    change_table :authors do |t|
      t.index :name, unique: true
    end

    change_table :artists do |t|
      t.index :name, unique: true
    end

    change_table :languages do |t|
      t.index :language, unique: true
    end

    change_table :places do |t|
      t.index :name, unique: true
    end

    change_table :scribes do |t|
      t.index :name, unique: true
    end

  end
end
