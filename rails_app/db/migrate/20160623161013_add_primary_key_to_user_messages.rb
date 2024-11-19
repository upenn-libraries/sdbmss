class AddPrimaryKeyToUserMessages < ActiveRecord::Migration
  def change
    add_column :user_messages, :id, :primary_key
  end
end
