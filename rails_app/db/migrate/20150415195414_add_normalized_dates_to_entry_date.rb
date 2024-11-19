class AddNormalizedDatesToEntryDate < ActiveRecord::Migration
  def change
    add_column :entry_dates, :date_normalized_start, :string
    add_column :entry_dates, :date_normalized_end, :string
  end
end
