class AddDeletedToLanguages < ActiveRecord::Migration[4.2]
  def change
    add_column :languages, :deleted, :boolean, :default => false
  end
end
