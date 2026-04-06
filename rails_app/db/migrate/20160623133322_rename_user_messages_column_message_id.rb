class RenameUserMessagesColumnMessageId < ActiveRecord::Migration[4.2]
  def change
    rename_column :user_messages, :message_id, :private_message_id
  end
end
