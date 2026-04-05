class RenameGameRecordTable < ActiveRecord::Migration[4.2]
  def change
    rename_table :dericci_game_record, :dericci_game_records
  end
end
