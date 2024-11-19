class AddObservedNameToEntryScribe < ActiveRecord::Migration
  def change
    add_column :entry_scribes, :observed_name, :string
  end
end
