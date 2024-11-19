class ChangeApprovedFlags < ActiveRecord::Migration
  def change
    remove_foreign_key :names, column: :approved_by_id
    remove_column :names, :approved
    remove_column :names, :approved_by_id
    remove_column :names, :approved_date
    add_column :names, :reviewed, :boolean, :default => false
    add_reference :names, :reviewed_by, :index => true
    add_column :names, :reviewed_date, :datetime
    add_foreign_key :names, :users, column: :reviewed_by_id

    remove_foreign_key :places, column: :approved_by_id
    remove_column :places, :approved
    remove_column :places, :approved_by_id
    remove_column :places, :approved_date
    add_column :places, :reviewed, :boolean, :default => false
    add_reference :places, :reviewed_by, :index => true
    add_column :places, :reviewed_date, :datetime
    add_foreign_key :places, :users, column: :reviewed_by_id

    add_column :languages, :reviewed, :boolean, :default => false
    add_reference :languages, :reviewed_by, :index => true
    add_column :languages, :reviewed_date, :datetime
    add_foreign_key :languages, :users, column: :reviewed_by_id

    add_column :manuscripts, :reviewed, :boolean, :default => false
    add_reference :manuscripts, :reviewed_by, :index => true
    add_column :manuscripts, :reviewed_date, :datetime
    add_foreign_key :manuscripts, :users, column: :reviewed_by_id

    add_column :sources, :reviewed, :boolean, :default => false
    add_reference :sources, :reviewed_by, :index => true
    add_column :sources, :reviewed_date, :datetime
    add_foreign_key :sources, :users, column: :reviewed_by_id

    add_reference :entries, :approved_by, :index => true
    add_column :entries, :approved_date, :datetime
    add_foreign_key :entries, :users, column: :approved_by_id
  end
end
