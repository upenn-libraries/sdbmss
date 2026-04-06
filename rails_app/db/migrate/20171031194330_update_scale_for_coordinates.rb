class UpdateScaleForCoordinates < ActiveRecord::Migration[4.2]
  def change
    change_column :places, :latitude, :decimal, :precision => 10, :scale => 6
    change_column :places, :longitude, :decimal, :precision => 10, :scale => 6
  end
end
