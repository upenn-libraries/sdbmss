class ChangeAcquireDateToStartDateInEvents < ActiveRecord::Migration[4.2]
  def change
    remove_column :events, :acquire_date
    add_column :events, :start_date, :string
  end
end
