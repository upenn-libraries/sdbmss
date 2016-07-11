class RenameCommentToOtherInfoNames < ActiveRecord::Migration
  def change
    rename_column :names, :comment, :other_info
  end
end
