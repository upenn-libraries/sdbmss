class DropOldFieldsFromEntryDate < ActiveRecord::Migration
  def change
    remove_column :entry_dates, :circa
    remove_column :entry_dates, :date
  end
end
