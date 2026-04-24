class AddEvidenceTextFieldToPlaces < ActiveRecord::Migration[4.2]
  def change
    add_column :places, :evidence, :text
  end
end
