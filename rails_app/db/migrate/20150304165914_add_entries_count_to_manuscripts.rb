class AddEntriesCountToManuscripts < ActiveRecord::Migration
  def change
    add_column :manuscripts, :entries_count, :integer
  end
end
