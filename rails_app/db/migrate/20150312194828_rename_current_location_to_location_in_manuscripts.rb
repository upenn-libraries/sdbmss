class RenameCurrentLocationToLocationInManuscripts < ActiveRecord::Migration
  def change
    remove_column :manuscripts, :current_location
    add_column :manuscripts, :location, :string
  end
end
