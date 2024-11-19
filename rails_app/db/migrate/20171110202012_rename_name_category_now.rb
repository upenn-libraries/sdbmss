class RenameNameCategoryNow < ActiveRecord::Migration
  def change
    rename_column :names, :category, :subtype
  end
end
