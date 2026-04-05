class CreateManuscripts < ActiveRecord::Migration[4.2]
  def change
    create_table :manuscripts do |t|

      t.timestamps
    end
  end
end
