class AddNotifiedTypeAlso < ActiveRecord::Migration[4.2]
  def change
    add_column :notifications, :notified_type, :string
  end
end
