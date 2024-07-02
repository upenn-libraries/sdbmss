class AddFlaggedProgressAndVerifiedId < ActiveRecord::Migration
  def change
    add_column :dericci_games, :flagged, :integer, :default => 0
    add_column :dericci_records, :verified_id, :integer
    remove_column :dericci_records, :verified
  end
end
