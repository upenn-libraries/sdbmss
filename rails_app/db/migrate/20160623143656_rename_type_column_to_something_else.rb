class RenameTypeColumnToSomethingElse < ActiveRecord::Migration[4.2]
  def change
    rename_column :user_messages, :type, :method
  end
end
