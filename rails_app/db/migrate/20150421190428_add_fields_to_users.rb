class AddFieldsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :email_is_public, :boolean, :default => false
    add_column :users, :bio, :text
  end
end
