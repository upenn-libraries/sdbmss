class ChangeAcquireDateToStartDateInEvents < ActiveRecord::Migration
  def change
    remove_column :events, :acquire_date
    add_column :events, :start_date, :string
  end
end
