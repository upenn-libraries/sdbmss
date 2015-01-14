class AddRoleToEntryAuthor < ActiveRecord::Migration
  def change
    add_column :entry_authors, :role, :string
  end
end
