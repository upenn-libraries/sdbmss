class AddIsAcceptedToComments < ActiveRecord::Migration
  def change
    add_column :comments, :is_accepted, :boolean, :default => false
  end
end
