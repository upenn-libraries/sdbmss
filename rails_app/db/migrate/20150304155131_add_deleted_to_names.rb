class AddDeletedToNames < ActiveRecord::Migration[4.2]
  def change
    add_column :names, :deleted, :boolean, :default => false
  end
end
