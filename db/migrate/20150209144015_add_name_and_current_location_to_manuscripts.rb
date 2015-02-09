class AddNameAndCurrentLocationToManuscripts < ActiveRecord::Migration
  def change
    add_column :manuscripts, :name, :string
    add_column :manuscripts, :current_location, :string
  end
end
