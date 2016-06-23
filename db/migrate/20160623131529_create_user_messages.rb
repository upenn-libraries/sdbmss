class CreateUserMessages < ActiveRecord::Migration
  def change
    create_join_table :products, :categories, table_name: :user_messages
    add_column :private_messages, :title, :text
  end
end
