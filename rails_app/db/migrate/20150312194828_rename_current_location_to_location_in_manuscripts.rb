class RenameCurrentLocationToLocationInManuscripts < ActiveRecord::Migration[4.2]
  def change
    remove_column :manuscripts, :current_location
    add_column :manuscripts, :location, :string
  end
end
