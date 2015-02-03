class AddCertaintyFieldsToEverything < ActiveRecord::Migration
  def change
    add_column :entry_titles, :uncertain_in_source, :boolean, :default => false
    add_column :entry_titles, :supplied_by_data_entry, :boolean, :default => false

    add_column :entry_authors, :uncertain_in_source, :boolean, :default => false
    add_column :entry_authors, :supplied_by_data_entry, :boolean, :default => false

    add_column :entry_artists, :uncertain_in_source, :boolean, :default => false
    add_column :entry_artists, :supplied_by_data_entry, :boolean, :default => false

    add_column :entry_languages, :uncertain_in_source, :boolean, :default => false
    add_column :entry_languages, :supplied_by_data_entry, :boolean, :default => false

    add_column :entry_materials, :uncertain_in_source, :boolean, :default => false
    add_column :entry_materials, :supplied_by_data_entry, :boolean, :default => false

    add_column :entry_places, :uncertain_in_source, :boolean, :default => false
    add_column :entry_places, :supplied_by_data_entry, :boolean, :default => false

    add_column :event_agents, :uncertain_in_source, :boolean, :default => false
    add_column :event_agents, :supplied_by_data_entry, :boolean, :default => false

  end
end
