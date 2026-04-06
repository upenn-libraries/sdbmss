class AddIndexes3 < ActiveRecord::Migration[4.2]
  def change
    change_table :event_agents do |t|
      t.index :observed_name
    end
  end
end
