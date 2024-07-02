class ChangeLanguage < ActiveRecord::Migration
  def change
    change_table :languages do |t|
      t.remove :language
    end
    add_column :languages, :name, :string
  end
end
