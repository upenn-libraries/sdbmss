class RenameFileTypeToCategory < ActiveRecord::Migration[4.2]
  def change
    rename_column :pages, :file_type, :category
  end
end
  