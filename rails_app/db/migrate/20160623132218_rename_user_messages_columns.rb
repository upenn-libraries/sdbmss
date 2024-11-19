class RenameUserMessagesColumns < ActiveRecord::Migration
  def change
    rename_column :user_messages, :product_id, :user_id
    rename_column :user_messages, :category_id, :message_id 
  end
end
