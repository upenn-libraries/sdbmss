class AddObservedDateToEntryDate < ActiveRecord::Migration[4.2]
  def change
    add_column :entry_dates, :observed_date, :string
  end
end
