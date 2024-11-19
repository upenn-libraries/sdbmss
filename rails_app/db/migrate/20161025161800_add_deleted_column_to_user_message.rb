class AddDeletedColumnToUserMessage < ActiveRecord::Migration
  def change
    add_column :user_messages, :deleted, :boolean, default: false
  end
end
