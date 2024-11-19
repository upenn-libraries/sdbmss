class AddNotifiedTypeAlso < ActiveRecord::Migration
  def change
    add_column :notifications, :notified_type, :string
  end
end
