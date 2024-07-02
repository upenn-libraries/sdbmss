class TweakCommentsFields < ActiveRecord::Migration
  def change
    remove_column :entry_comments, :public
    add_column :entry_comments, :public, :boolean, :default => true
    add_column :entry_comments, :is_correction, :boolean, :default => false
  end
end
