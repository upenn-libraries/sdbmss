class RenameNameTypeField < ActiveRecord::Migration[4.2]
  def change
    rename_column :names, :type, :category
  end
end
