class AddPrimaryKeyToUserMessages < ActiveRecord::Migration[4.2]
  def change
    add_column :user_messages, :id, :primary_key
  end
end
