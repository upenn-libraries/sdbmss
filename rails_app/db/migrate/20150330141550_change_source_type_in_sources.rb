class ChangeSourceTypeInSources < ActiveRecord::Migration[4.2]
  def change
    remove_column :sources, :source_type
    add_reference(:sources, :source_type, index: true)
  end
end
