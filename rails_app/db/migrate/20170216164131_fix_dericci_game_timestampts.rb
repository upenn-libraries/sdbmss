class FixDericciGameTimestampts < ActiveRecord::Migration
  def change
    remove_column :dericci_games, :created_at
    remove_column :dericci_games, :updated_at
    change_table :dericci_games do |t|
      t.timestamps
    end
  end
end
