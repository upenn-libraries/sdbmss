class CreateAuthors < ActiveRecord::Migration
  def change
    create_table :authors do |t|
      t.string :name
      t.references :entry, index: true
      t.string :viaf_id
      t.boolean :approved
      t.references :approved_by, index: true
      t.datetime :approved_date

    end
  end
end
