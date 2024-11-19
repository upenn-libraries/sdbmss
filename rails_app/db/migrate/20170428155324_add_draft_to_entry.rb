class AddDraftToEntry < ActiveRecord::Migration
  def change
    add_column :entries, :draft, :boolean, :default => false
  end
end
