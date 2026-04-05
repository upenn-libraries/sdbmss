class AddUserFieldstoGroupUser < ActiveRecord::Migration[4.2]
  def change
    add_column :group_users, :created_by, :integer, :index => true
  end
end
