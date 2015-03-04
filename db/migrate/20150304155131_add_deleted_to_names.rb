class AddDeletedToNames < ActiveRecord::Migration
  def change
    add_column :names, :deleted, :boolean, :default => false
  end
end
