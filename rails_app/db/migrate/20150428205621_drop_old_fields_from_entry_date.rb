class DropOldFieldsFromEntryDate < ActiveRecord::Migration[4.2]
  def change
    remove_column :entry_dates, :circa
    remove_column :entry_dates, :date
  end
end
