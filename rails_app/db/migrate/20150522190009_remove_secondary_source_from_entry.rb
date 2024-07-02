class RemoveSecondarySourceFromEntry < ActiveRecord::Migration
  def change
    remove_column :entries, :secondary_source
  end
end
