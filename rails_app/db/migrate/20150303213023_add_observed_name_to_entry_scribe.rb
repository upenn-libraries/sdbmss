class AddObservedNameToEntryScribe < ActiveRecord::Migration[4.2]
  def change
    add_column :entry_scribes, :observed_name, :string
  end
end
