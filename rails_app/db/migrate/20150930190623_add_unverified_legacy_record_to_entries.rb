class AddUnverifiedLegacyRecordToEntries < ActiveRecord::Migration
  def change
    add_column :entries, :unverified_legacy_record, :boolean, default: false
  end
end
