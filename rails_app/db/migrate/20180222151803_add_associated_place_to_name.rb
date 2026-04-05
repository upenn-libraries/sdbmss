class AddAssociatedPlaceToName < ActiveRecord::Migration[4.2]
  def change
    add_reference :names, :associated_place
  end
end
