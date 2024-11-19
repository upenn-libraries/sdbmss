class AddQualifierToRatings < ActiveRecord::Migration
  def change
    add_column :ratings, :qualifier, :string, :default => "confirm"
  end
end
