class CreateManuscripts < ActiveRecord::Migration
  def change
    create_table :manuscripts do |t|

      t.timestamps
    end
  end
end
