class ChangeCertaintyFieldNamesInEntryScribe < ActiveRecord::Migration
  def change
    rename_column :entry_scribes, :inferred_by_source, :uncertain_in_source
    rename_column :entry_scribes, :inferred_by_user, :supplied_by_data_entry
  end
end
