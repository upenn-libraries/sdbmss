class AddEditableToGroupRecord < ActiveRecord::Migration
  def change
    add_column :group_records, :editable, :boolean, :default => false
  end
end
