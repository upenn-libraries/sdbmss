class ChangePrice < ActiveRecord::Migration[4.2]
  def change
    change_table :events do |t|
      t.change :price, :decimal, precision: 20, scale: 2
    end

  end
end
