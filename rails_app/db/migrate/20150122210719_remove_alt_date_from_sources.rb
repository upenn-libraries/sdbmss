class RemoveAltDateFromSources < ActiveRecord::Migration[4.2]
  def change
    remove_column :sources, :alt_date
  end
end
