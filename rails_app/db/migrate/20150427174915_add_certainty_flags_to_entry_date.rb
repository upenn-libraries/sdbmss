class AddCertaintyFlagsToEntryDate < ActiveRecord::Migration[4.2]
  def change
    add_column :entry_dates, :uncertain_in_source, :boolean, :default => false
    add_column :entry_dates, :supplied_by_data_entry, :boolean, :default => false
  end
end
