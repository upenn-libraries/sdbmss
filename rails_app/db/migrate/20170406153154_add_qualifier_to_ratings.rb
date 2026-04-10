class AddQualifierToRatings < ActiveRecord::Migration[4.2]
  def change
    add_column :ratings, :qualifier, :string, :default => "confirm"
  end
end
