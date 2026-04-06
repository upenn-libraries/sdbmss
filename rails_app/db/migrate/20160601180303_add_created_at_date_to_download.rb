class AddCreatedAtDateToDownload < ActiveRecord::Migration[4.2]
  def change
    add_column :downloads, :created_at, :datetime
  end
end
