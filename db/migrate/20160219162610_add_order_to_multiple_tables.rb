class AddOrderToMultipleTables < ActiveRecord::Migration
  def change
    add_column :entry_authors, :order, :integer
    add_column :entry_dates, :order, :integer
    add_column :entry_artists, :order, :integer
    add_column :entry_scribes, :order, :integer
    add_column :entry_languages, :order, :integer
    add_column :entry_materials, :order, :integer
    add_column :entry_places, :order, :integer
    add_column :entry_uses, :order, :integer
    add_column :provenance, :order, :integer
  end
end
