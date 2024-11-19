class RenameUserCreatedColumnsForGroups < ActiveRecord::Migration
  def change
    rename_column :groups, :created_by, :created_by_id
    rename_column :groups, :updated_by, :updated_by_id
  end
end
