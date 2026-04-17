class AddUnreadToPrivateMessages < ActiveRecord::Migration[4.2]
  def change
    add_column :private_messages, :unread, :boolean, default: true
  end
end
