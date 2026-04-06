class CreateAgents < ActiveRecord::Migration[4.2]
  def change
    create_table :agents do |t|
      t.references :entry, index: true
      t.integer :viaf_id
      t.string :name
      t.string :agent_type
      t.boolean :approved
      t.references :approved_by, index: true
      t.datetime :approved_date

    end
  end
end
