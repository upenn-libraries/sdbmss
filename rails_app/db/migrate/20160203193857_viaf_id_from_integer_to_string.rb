class ViafIdFromIntegerToString < ActiveRecord::Migration
  def change
    change_table :names do |t|
      t.change :viaf_id, :string
    end
  end
end
