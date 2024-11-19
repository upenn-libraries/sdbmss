class AddUrlToManuscript < ActiveRecord::Migration
  def change
    add_column :manuscripts, :url, :string
  end
end
