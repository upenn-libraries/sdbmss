class ChangeStatusInDownloads < ActiveRecord::Migration[4.2]
  def change
    change_column :downloads, :status, :integer, :default => 0
  end
end
