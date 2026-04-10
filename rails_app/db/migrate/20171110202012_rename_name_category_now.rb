class RenameNameCategoryNow < ActiveRecord::Migration[4.2]
  def change
    rename_column :names, :category, :subtype
  end
end
