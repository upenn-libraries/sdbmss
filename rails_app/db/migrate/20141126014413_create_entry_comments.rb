class CreateEntryComments < ActiveRecord::Migration
  def change
    create_table :entry_comments do |t|
      t.references :entry, index: true
      t.text :comment
      t.boolean :public
      t.datetime :date
      t.datetime :added_on
      t.references :added_by, index: true

    end
  end
end
