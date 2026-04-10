class DropTableAgents < ActiveRecord::Migration[4.2]
  def change
    drop_table :agents
    drop_table :artists
    drop_table :scribes
  end
end
