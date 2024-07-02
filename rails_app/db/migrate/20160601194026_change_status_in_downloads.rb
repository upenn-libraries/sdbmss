class ChangeStatusInDownloads < ActiveRecord::Migration
  def change
    change_column :downloads, :status, :integer, :default => 0
  end
end
