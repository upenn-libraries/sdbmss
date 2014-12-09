class CreateEventAgents < ActiveRecord::Migration
  def change
    create_table :event_agents do |t|
      t.references :event, index: true
      t.string :observed_name
      t.references :agent, index: true
      t.string :role

    end
  end
end
