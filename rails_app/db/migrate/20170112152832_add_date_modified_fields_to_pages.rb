class AddDateModifiedFieldsToPages < ActiveRecord::Migration[4.2]
  def change
    add_column(:pages, :created_at, :datetime, :default => Time.now)
    add_column(:pages, :updated_at, :datetime, :default => Time.now)
  end
end
