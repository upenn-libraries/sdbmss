class AddObservedNameToSourceAgent < ActiveRecord::Migration
  def change
    add_column :source_agents, :observed_name, :string
  end
end
