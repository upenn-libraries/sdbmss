class AddDescriptionToGroups < ActiveRecord::Migration[4.2]
  def change
    add_column :groups, :description, :text
  end
end
