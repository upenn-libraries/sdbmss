class ChangeEntryDateFields < ActiveRecord::Migration
  def change
    change_column :entries, :added_on, :datetime
    change_column :entries, :last_modified, :datetime
  end
end
