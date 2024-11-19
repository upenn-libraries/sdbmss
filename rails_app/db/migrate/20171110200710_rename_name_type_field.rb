class RenameNameTypeField < ActiveRecord::Migration
  def change
    rename_column :names, :type, :category
  end
end
