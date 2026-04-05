class RenameApprovedDateToApprovedAt < ActiveRecord::Migration[4.2]
  def change
    remove_column :entries, :approved_date
    add_column :entries, :approved_at, :datetime
  end
end
