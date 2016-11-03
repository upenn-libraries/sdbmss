class AddUserWorkflowColumnsToGroupUser < ActiveRecord::Migration
  def change
    add_column :group_users, :role, :string, default: "Member"
    add_column :group_users, :confirmed, :boolean, default: false
  end
end
