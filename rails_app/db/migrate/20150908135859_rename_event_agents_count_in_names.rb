class RenameEventAgentsCountInNames < ActiveRecord::Migration[4.2]
  def change
    rename_column :names, :event_agents_count, :sale_agents_count
  end
end
