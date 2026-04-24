class AddNameAndCurrentLocationToManuscripts < ActiveRecord::Migration[4.2]
  def change
    add_column :manuscripts, :name, :string
    add_column :manuscripts, :current_location, :string
  end
end
