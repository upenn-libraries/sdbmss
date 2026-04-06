class AddAsRecordedToMaterialAndLanguage < ActiveRecord::Migration[4.2]
  def change
    add_column :entry_languages, :observed_name, :string
    add_column :entry_materials, :observed_name, :string
  end
end
