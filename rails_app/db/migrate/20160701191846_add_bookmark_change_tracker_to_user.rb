class AddBookmarkChangeTrackerToUser < ActiveRecord::Migration
  def change
    add_column :users, :bookmark_tracker, :integer, default: 0
  end
end
