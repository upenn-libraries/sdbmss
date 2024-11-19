class AddDeletedToLanguages < ActiveRecord::Migration
  def change
    add_column :languages, :deleted, :boolean, :default => false
  end
end
