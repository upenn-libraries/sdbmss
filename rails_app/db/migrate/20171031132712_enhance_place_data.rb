class EnhancePlaceData < ActiveRecord::Migration
  def change
    add_column :places, :latitude, :decimal
    add_column :places, :longitude, :decimal
    add_reference :places, :parent
    add_column :places, :authority_id, :integer
    add_column :places, :authority_source, :string
  end
end
