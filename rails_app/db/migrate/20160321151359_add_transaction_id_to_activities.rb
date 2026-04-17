class AddTransactionIdToActivities < ActiveRecord::Migration[4.2]
  def change
    add_column :activities, :transaction_id, :integer
  end
end
