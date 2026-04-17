class AddNormalizedDatesToEvent < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :start_date_normalized_start, :string
    add_column :events, :start_date_normalized_end, :string
    add_column :events, :end_date_normalized_start, :string
    add_column :events, :end_date_normalized_end, :string
  end
end
