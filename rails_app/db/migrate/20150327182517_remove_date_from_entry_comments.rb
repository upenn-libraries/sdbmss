class RemoveDateFromEntryComments < ActiveRecord::Migration[4.2]
  def change
    remove_column :entry_comments, :date
  end
end
