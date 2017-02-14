class RenameGameIdColumn < ActiveRecord::Migration
  def change
    rename_column :dericci_links, :game_id, :dericci_game_id
  end
end
