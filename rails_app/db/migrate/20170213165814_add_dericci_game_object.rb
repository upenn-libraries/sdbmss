class AddDericciGameObject < ActiveRecord::Migration
  def change
    create_table :dericci_games do |t|
      t.integer :created_by_id, index: true
      t.datetime :created_at
      t.boolean :reviewed
    end    
    add_column :dericci_links, :game_id, :integer
    add_column :dericci_links, :other_info, :text
  end
end
