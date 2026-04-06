class AddTransactionTypeToEntry < ActiveRecord::Migration[4.2]
  def change
    add_column :entries, :transaction_type, :string
  end
end
