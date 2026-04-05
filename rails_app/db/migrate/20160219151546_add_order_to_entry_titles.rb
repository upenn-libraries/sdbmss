class AddOrderToEntryTitles < ActiveRecord::Migration[4.2]
  def change
    add_column :entry_titles, :order, :integer
  end
end
