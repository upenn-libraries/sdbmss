class AddGameItemAndReliability < ActiveRecord::Migration
  def change
    create_table :dericci_game_record do |t|
      t.integer :dericci_game_id
      t.integer :dericci_record_id
    end
    add_column :dericci_links, :reliability, :integer, default: 0
  end
end
