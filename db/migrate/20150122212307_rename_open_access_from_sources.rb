class RenameOpenAccessFromSources < ActiveRecord::Migration
  def change
    remove_column :sources, :electronic_catalog_open_access
    add_column :sources, :electronic_publicly_available, :string
  end
end
