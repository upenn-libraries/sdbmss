class AddUserFieldstoGroupUser < ActiveRecord::Migration
  def change
    add_column :group_users, :created_by, :integer, :index => true
  end
end
