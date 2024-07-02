class RenameApprovedDateToApprovedAt < ActiveRecord::Migration
  def change
    remove_column :entries, :approved_date
    add_column :entries, :approved_at, :datetime
  end
end
