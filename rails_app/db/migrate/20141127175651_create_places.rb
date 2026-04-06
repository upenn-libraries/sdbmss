class CreatePlaces < ActiveRecord::Migration[4.2]
  def change
    create_table :places do |t|
      t.string :name
      t.references :entry, index: true
      t.boolean :approved
      t.references :approved_by, index: true
      t.datetime :approved_date
    end
  end
end
