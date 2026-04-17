class RenameGameIdColumn < ActiveRecord::Migration[4.2]
  def change
    rename_column :dericci_links, :game_id, :dericci_game_id
  end
end
