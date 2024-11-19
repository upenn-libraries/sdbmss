class RemoveDateFromEntryComments < ActiveRecord::Migration
  def change
    remove_column :entry_comments, :date
  end
end
