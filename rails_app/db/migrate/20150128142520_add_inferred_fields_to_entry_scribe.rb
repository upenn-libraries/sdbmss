class AddInferredFieldsToEntryScribe < ActiveRecord::Migration[4.2]
  def change
    add_column :entry_scribes, :inferred_by_source, :boolean, :default => false
    add_column :entry_scribes, :inferred_by_user, :boolean, :default => false
  end
end
