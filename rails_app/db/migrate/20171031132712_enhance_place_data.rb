class EnhancePlaceData < ActiveRecord::Migration[4.2]
  def change
    add_column :places, :latitude, :decimal
    add_column :places, :longitude, :decimal
    add_reference :places, :parent
    add_column :places, :authority_id, :integer
    add_column :places, :authority_source, :string
  end
end
