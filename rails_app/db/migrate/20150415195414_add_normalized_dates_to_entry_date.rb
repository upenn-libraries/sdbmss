class AddNormalizedDatesToEntryDate < ActiveRecord::Migration[4.2]
  def change
    add_column :entry_dates, :date_normalized_start, :string
    add_column :entry_dates, :date_normalized_end, :string
  end
end
