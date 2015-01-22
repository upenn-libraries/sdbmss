class RemoveAltDateFromSources < ActiveRecord::Migration
  def change
    remove_column :sources, :alt_date
  end
end
