class AddNormalizedDatesToEvent < ActiveRecord::Migration
  def change
    add_column :events, :start_date_normalized_start, :string
    add_column :events, :start_date_normalized_end, :string
    add_column :events, :end_date_normalized_start, :string
    add_column :events, :end_date_normalized_end, :string
  end
end
