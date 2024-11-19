class RenameUserMessagesColumnMessageId < ActiveRecord::Migration
  def change
    rename_column :user_messages, :message_id, :private_message_id
  end
end
