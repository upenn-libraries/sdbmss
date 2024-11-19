class AddDeletedColumnToCommentsAndReplies < ActiveRecord::Migration
  def change
    add_column :replies, :deleted, :boolean, default: false
  end
end
