class DropObsoleteTables < ActiveRecord::Migration
  def change
    drop_table :artists
    drop_table :authors
    drop_table :agents
    drop_table :scribes
  end
end
