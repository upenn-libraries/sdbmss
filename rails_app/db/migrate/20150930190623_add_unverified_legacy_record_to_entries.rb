class AddUnverifiedLegacyRecordToEntries < ActiveRecord::Migration[4.2]
  def change
    add_column :entries, :unverified_legacy_record, :boolean, default: false
  end
end
