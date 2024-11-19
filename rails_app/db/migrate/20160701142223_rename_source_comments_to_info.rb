class RenameSourceCommentsToInfo < ActiveRecord::Migration
  def change
    rename_column :sources, :comments, :other_info
  end
end
