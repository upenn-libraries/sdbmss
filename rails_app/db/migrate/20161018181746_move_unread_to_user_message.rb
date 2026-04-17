class MoveUnreadToUserMessage < ActiveRecord::Migration[4.2]
  def change
    remove_column :private_messages, :unread
    add_column :user_messages, :unread, :boolean, :default => true
  end
end
