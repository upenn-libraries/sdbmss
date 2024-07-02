class AddTriesToJenaResponse < ActiveRecord::Migration
  def change
    add_column :jena_responses, :tries, :integer, :default => 0
  end
end
