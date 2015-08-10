class AddReviewedFieldsToEntryManuscript < ActiveRecord::Migration
  def change
    add_column :entry_manuscripts, :reviewed, :boolean, :default => false
    add_reference :entry_manuscripts, :reviewed_by, :index => true
    add_column :entry_manuscripts, :reviewed_at, :datetime
    add_foreign_key :entry_manuscripts, :users, column: :reviewed_by_id
  end
end
