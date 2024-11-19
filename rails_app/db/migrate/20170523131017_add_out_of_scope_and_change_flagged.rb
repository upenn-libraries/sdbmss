class AddOutOfScopeAndChangeFlagged < ActiveRecord::Migration
  def change
    change_column :dericci_records, :flagged, :text, :default => nil
    add_column :dericci_records, :out_of_scope, :boolean, :default => false
  end
end
