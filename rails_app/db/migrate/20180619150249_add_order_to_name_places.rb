class AddOrderToNamePlaces < ActiveRecord::Migration
  def change
    add_column :name_places, :order, :integer
  end
end
