class RenameEventAgentsCountInNames < ActiveRecord::Migration
  def change
    rename_column :names, :event_agents_count, :sale_agents_count
  end
end
