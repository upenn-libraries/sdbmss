class CreateReplies < ActiveRecord::Migration[4.2]
  def change
    create_table :replies do |t|
      t.text :reply
      t.references :comment, index: true, foreign_key: true
      t.references :created_by, index: true
      t.references :updated_by, index: true
      t.datetime :created_at
      t.datetime :updated_at

      t.timestamps null: false
    end
  end
end
