class CreateDownloads < ActiveRecord::Migration[4.2]
  def change
    create_table :downloads do |t|
      t.string :filename
      t.integer :status
    end
  end
end
