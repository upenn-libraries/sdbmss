class AddProgressFieldsToGame < ActiveRecord::Migration
  def change
    add_column :dericci_games, :skipped, :integer
    add_column :dericci_games, :completed, :integer
    add_column :dericci_games, :updated_at, :datetime
  end
end
