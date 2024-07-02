class AddTagsToBookmarks < ActiveRecord::Migration
  def change
    add_column :bookmarks, :tags, :text
  end
end
