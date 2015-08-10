class AddCreatedByAndUpdatedByToEntryManuscript < ActiveRecord::Migration
  def change
    add_reference :entry_manuscripts, :created_by, :index => true
    add_reference :entry_manuscripts, :updated_by, :index => true
    add_foreign_key :entry_manuscripts, :users, column: :created_by_id
    add_foreign_key :entry_manuscripts, :users, column: :updated_by_id
  end
end
