class AddLegacyFlagToSource < ActiveRecord::Migration
  def change
    add_column :sources, :legacy, :boolean, :default => false
  end
end
