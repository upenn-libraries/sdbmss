class RenamePageTypeToFileType < ActiveRecord::Migration[4.2]
  def change
    rename_column :pages, :type, :file_type
  end
end
