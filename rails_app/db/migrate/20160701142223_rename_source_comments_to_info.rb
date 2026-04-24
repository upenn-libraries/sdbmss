class RenameSourceCommentsToInfo < ActiveRecord::Migration[4.2]
  def change
    rename_column :sources, :comments, :other_info
  end
end
