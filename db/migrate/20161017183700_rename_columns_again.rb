class RenameColumnsAgain < ActiveRecord::Migration
  def change
    add_column :group_users, :created_by_id, :integer, :index => true
    remove_column :group_users, :created_by
  end
end
