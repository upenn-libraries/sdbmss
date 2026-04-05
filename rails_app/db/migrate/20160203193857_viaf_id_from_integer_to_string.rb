class ViafIdFromIntegerToString < ActiveRecord::Migration[4.2]
  def change
    change_table :names do |t|
      t.change :viaf_id, :string
    end
  end
end
