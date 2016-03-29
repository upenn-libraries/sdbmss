class AddTransactionIdToEntryManuscriptActivities < ActiveRecord::Migration
  def change
    add_column :entry_manuscript_activities, :transaction_id, :integer
  end
end
