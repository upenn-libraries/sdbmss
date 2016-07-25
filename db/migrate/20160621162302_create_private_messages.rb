class CreatePrivateMessages < ActiveRecord::Migration
  def change
    create_table :private_messages do |t|
      t.text :message
      t.datetime :created_at
      t.datetime :updated_at
      t.boolean  :deleted, default: false
    end

    add_reference :private_messages, :created_by, :index => true
    add_reference :private_messages, :updated_by, :index => true

    add_foreign_key :private_messages, :users, column: :created_by_id
    add_foreign_key :private_messages, :users, column: :updated_by_id

    add_reference :private_messages, :user, :index => true
    add_reference :private_messages, :private_message, :index => true

    add_foreign_key :private_messages, :entries, column: :user_id
    add_foreign_key :private_messages, :private_messages, column: :private_message_id
  end
end
