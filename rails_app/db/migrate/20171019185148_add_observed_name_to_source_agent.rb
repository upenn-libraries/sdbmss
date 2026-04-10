class AddObservedNameToSourceAgent < ActiveRecord::Migration[4.2]
  def change
    add_column :source_agents, :observed_name, :string
  end
end
