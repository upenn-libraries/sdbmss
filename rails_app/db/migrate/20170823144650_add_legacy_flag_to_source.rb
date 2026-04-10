class AddLegacyFlagToSource < ActiveRecord::Migration[4.2]
  def change
    add_column :sources, :legacy, :boolean, :default => false
  end
end
