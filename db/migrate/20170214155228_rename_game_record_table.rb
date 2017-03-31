class RenameGameRecordTable < ActiveRecord::Migration
  def change
    rename_table :dericci_game_record, :dericci_game_records
  end
end
