class ChangePrice < ActiveRecord::Migration
  def change
    change_table :events do |t|
      t.change :price, :decimal, precision: 20, scale: 2
    end

  end
end
