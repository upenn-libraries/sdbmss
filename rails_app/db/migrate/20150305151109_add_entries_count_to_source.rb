class AddEntriesCountToSource < ActiveRecord::Migration
  def change
    add_column :sources, :entries_count, :integer
  end
end
