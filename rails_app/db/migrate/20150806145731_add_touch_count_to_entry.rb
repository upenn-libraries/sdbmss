class AddTouchCountToEntry < ActiveRecord::Migration
  def change
    add_column :entries, :touch_count, :integer, :default => 0, :null => false
  end
end
