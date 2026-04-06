class AddDeletedColumnToUserMessage < ActiveRecord::Migration[4.2]
  def change
    add_column :user_messages, :deleted, :boolean, default: false
  end
end
