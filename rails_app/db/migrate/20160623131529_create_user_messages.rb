class CreateUserMessages < ActiveRecord::Migration[4.2]
  def change
    create_join_table :products, :categories, table_name: :user_messages
    add_column :private_messages, :title, :text
  end
end
