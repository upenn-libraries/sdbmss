class AddBookmarkChangeTrackerToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :bookmark_tracker, :integer, default: 0
  end
end
