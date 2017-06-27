class AddFlagAndVerifiedToDericciRecord < ActiveRecord::Migration
  def change
    add_column :dericci_records, :flagged, :boolean, :default => false
    add_column :dericci_records, :verified, :boolean, :default => false
  end
end
