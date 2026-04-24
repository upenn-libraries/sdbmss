class AddDeletedColumnToCommentsAndReplies < ActiveRecord::Migration[4.2]
  def change
    add_column :replies, :deleted, :boolean, default: false
  end
end
