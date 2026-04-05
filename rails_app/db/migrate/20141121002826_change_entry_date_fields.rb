class ChangeEntryDateFields < ActiveRecord::Migration[4.2]
  def change
    change_column :entries, :added_on, :datetime
    change_column :entries, :last_modified, :datetime
  end
end
