class ForceUniqueForPages < ActiveRecord::Migration[4.2]
  def change
    remove_index :pages, :name
    remove_index :pages, :filename

    add_index :pages, :name, unique: true
    add_index :pages, :filename, unique: true    
  end
end
