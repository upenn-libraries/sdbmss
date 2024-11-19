class DropTableAgents < ActiveRecord::Migration
  def change
    drop_table :agents
    drop_table :artists
    drop_table :scribes
  end
end
