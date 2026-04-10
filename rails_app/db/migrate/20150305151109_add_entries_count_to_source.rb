class AddEntriesCountToSource < ActiveRecord::Migration[4.2]
  def change
    add_column :sources, :entries_count, :integer
  end
end
