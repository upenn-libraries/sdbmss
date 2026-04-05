class MakePageFieldsUnique < ActiveRecord::Migration[4.2]
  def change
    add_index :pages, :name
    add_index :pages, :filename
  end
end
