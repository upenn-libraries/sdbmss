class AddTypeToPage < ActiveRecord::Migration[4.2]
  def change
    add_column :pages, :type, :string, default: "page"
  end
end
