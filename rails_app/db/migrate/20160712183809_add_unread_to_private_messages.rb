class AddUnreadToPrivateMessages < ActiveRecord::Migration
  def change
    add_column :private_messages, :unread, :boolean, default: true
  end
end
