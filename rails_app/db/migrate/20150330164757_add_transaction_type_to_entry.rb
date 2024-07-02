class AddTransactionTypeToEntry < ActiveRecord::Migration
  def change
    add_column :entries, :transaction_type, :string
  end
end
