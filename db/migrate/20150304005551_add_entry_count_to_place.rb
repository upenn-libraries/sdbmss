class AddEntryCountToPlace < ActiveRecord::Migration
  def change
    add_column :places, :entries_count, :integer
    add_column :languages, :entries_count, :integer
    add_column :names, :authors_count, :integer
    add_column :names, :artists_count, :integer
    add_column :names, :scribes_count, :integer
    add_column :names, :source_agents_count, :integer
    add_column :names, :event_agents_count, :integer
  end
end
