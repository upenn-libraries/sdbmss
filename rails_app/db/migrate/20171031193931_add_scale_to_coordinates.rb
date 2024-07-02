class AddScaleToCoordinates < ActiveRecord::Migration
  def change
    change_column :places, :latitude, :decimal, :precision => 10, :scale => 2
    change_column :places, :longitude, :decimal, :precision => 10, :scale => 2
  end
end
