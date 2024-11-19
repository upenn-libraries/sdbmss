class AddEvidenceTextFieldToPlaces < ActiveRecord::Migration
  def change
    add_column :places, :evidence, :text
  end
end
