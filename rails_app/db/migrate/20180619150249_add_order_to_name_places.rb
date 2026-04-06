class AddOrderToNamePlaces < ActiveRecord::Migration[4.2]
  def change
    add_column :name_places, :order, :integer
  end
end
