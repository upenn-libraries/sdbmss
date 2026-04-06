class AddEditableToGroupRecord < ActiveRecord::Migration[4.2]
  def change
    add_column :group_records, :editable, :boolean, :default => false
  end
end
