class RenameFileTypeToCategory < ActiveRecord::Migration
  def change
    rename_column :pages, :file_type, :category
  end
end
  