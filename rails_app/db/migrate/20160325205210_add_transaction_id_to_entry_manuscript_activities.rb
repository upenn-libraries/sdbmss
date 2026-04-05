class AddTransactionIdToEntryManuscriptActivities < ActiveRecord::Migration[4.2]
  def change
    add_column :entry_manuscript_activities, :transaction_id, :integer
  end
end
