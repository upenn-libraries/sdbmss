class AddReviewedFieldsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :reviewed, :boolean, :default => false
    add_reference :users, :reviewed_by, :index => true
    add_column :users, :reviewed_at, :datetime
    add_foreign_key :users, :users, column: :reviewed_by_id

    add_reference :users, :created_by, :index => true
    add_foreign_key :users, :users, column: :created_by_id

    add_reference :users, :updated_by, :index => true
    add_foreign_key :users, :users, column: :updated_by_id
  end
end
