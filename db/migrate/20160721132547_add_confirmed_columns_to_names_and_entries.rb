class AddConfirmedColumnsToNamesAndEntries < ActiveRecord::Migration
  def change
    add_column :entries, :confirmed, :boolean, :default => false
    add_column :names, :confirmed, :boolean, :default => false
  end
end
