class CreateScribes < ActiveRecord::Migration[4.2]
  def change
    create_table :scribes do |t|
      t.string :name

    end
  end
end
