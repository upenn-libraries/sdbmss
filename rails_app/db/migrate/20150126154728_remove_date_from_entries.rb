class RemoveDateFromEntries < ActiveRecord::Migration[4.2]
  def change
    remove_column :entries, :date
  end
end
