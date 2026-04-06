class AddEntriesCountToManuscripts < ActiveRecord::Migration[4.2]
  def change
    add_column :manuscripts, :entries_count, :integer
  end
end
