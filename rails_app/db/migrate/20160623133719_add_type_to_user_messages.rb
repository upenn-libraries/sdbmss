class AddTypeToUserMessages < ActiveRecord::Migration
  def change
    add_column :user_messages, :type, :string
  end
end
