class CreateEntryMaterials < ActiveRecord::Migration
  def change
    create_table :entry_materials do |t|
      t.references :entry, index: true
      t.string :material

    end
  end
end
