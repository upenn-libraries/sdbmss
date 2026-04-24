class AddProgressFieldsToGame < ActiveRecord::Migration[4.2]
  def change
    add_column :dericci_games, :skipped, :integer
    add_column :dericci_games, :completed, :integer
    add_column :dericci_games, :updated_at, :datetime
  end
end
