class CreateEntries < ActiveRecord::Migration
  def change
    create_table :entries do |t|
      t.string :date
      t.references :source, index: true
      t.string :catalog_or_lot_number
      t.string :secondary_source
      t.string :current_location
      t.integer :folios
      t.integer :num_columns
      t.integer :num_lines
      t.integer :height
      t.integer :width
      t.string :alt_size
      t.string :manuscript_binding, limit: 512
      t.text :other_info
      t.string :manuscript_link, limit: 1024
      t.integer :miniatures_fullpage
      t.integer :miniatures_large
      t.integer :miniatures_small
      t.integer :miniatures_unspec_size
      t.integer :initials_historiated
      t.integer :initials_decorated
      t.date :added_on
      t.references :added_by, index: true
      t.boolean :approved, default: false
      t.boolean :deleted, default: false
      t.date :last_modified, default: nil
      t.references :last_modified_by, index: true
 
    end
  end
end
