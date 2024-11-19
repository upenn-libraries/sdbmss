class RenameTypeColumnToSomethingElse < ActiveRecord::Migration
  def change
    rename_column :user_messages, :type, :method
  end
end
