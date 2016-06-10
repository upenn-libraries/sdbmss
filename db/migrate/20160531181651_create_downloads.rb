class CreateDownloads < ActiveRecord::Migration
  def change
    create_table :downloads do |t|
      t.string :filename
      t.integer :status
    end
  end
end
