class CreateArtists < ActiveRecord::Migration
  def change
    create_table :artists do |t|
      t.string :name
      t.references :entry, index: true
      t.boolean :approved
      t.references :approved_by, index: true
      t.datetime :approved_date
    end
  end
end
