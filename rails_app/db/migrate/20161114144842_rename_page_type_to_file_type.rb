class RenamePageTypeToFileType < ActiveRecord::Migration
  def change
    rename_column :pages, :type, :file_type
  end
end
