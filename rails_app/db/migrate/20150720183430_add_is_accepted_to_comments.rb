class AddIsAcceptedToComments < ActiveRecord::Migration[4.2]
  def change
    add_column :comments, :is_accepted, :boolean, :default => false
  end
end
