class AddJenaStatus < ActiveRecord::Migration[4.2]
  def change
    create_table :jena_responses do |t|
      t.text :message
      t.integer :status
      t.references :record, polymorphic: true, index: true
      t.timestamps null: false  
    end
  end
end
