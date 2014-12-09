class CreateScribes < ActiveRecord::Migration
  def change
    create_table :scribes do |t|
      t.string :name

    end
  end
end
