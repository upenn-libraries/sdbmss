class RemoveSecondarySourceFromEntry < ActiveRecord::Migration[4.2]
  def change
    remove_column :entries, :secondary_source
  end
end
