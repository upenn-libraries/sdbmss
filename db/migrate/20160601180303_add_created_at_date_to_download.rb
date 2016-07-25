class AddCreatedAtDateToDownload < ActiveRecord::Migration
  def change
    add_column :downloads, :created_at, :datetime
  end
end
