class RenameCommentToOtherInfoNames < ActiveRecord::Migration[4.2]
  def change
    rename_column :names, :comment, :other_info
  end
end
