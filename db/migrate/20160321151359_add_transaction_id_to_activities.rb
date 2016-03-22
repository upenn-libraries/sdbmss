class AddTransactionIdToActivities < ActiveRecord::Migration
  def change
    add_column :activities, :transaction_id, :integer
  end
end
