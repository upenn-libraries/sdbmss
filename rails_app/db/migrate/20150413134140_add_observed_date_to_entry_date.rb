class AddObservedDateToEntryDate < ActiveRecord::Migration
  def change
    add_column :entry_dates, :observed_date, :string
  end
end
