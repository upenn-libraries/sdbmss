class CreateSourceAgents < ActiveRecord::Migration
  def change
    create_table :source_agents do |t|
      t.references :source, index: true
      t.references :agent, index: true
      t.string :role

      t.timestamps
    end
  end
end
