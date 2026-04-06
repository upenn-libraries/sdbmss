class AddNameToPage < ActiveRecord::Migration[4.2]
  def change
    add_column :pages, :name, :string
  end
end
