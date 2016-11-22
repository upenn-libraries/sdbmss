class AddTypeToPage < ActiveRecord::Migration
  def change
    add_column :pages, :type, :string, default: "page"
  end
end
