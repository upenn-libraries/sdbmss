class AddOrderToEntryTitles < ActiveRecord::Migration
  def change
    add_column :entry_titles, :order, :integer
  end
end
