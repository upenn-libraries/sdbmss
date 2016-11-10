class MakePageFieldsUnique < ActiveRecord::Migration
  def change
    add_index :pages, :name
    add_index :pages, :filename
  end
end
