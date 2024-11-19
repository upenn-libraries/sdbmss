class AddAssociatedPlaceToName < ActiveRecord::Migration
  def change
    add_reference :names, :associated_place
  end
end
