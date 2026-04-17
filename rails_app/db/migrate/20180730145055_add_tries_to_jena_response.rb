class AddTriesToJenaResponse < ActiveRecord::Migration[4.2]
  def change
    add_column :jena_responses, :tries, :integer, :default => 0
  end
end
