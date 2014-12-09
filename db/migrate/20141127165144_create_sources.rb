class CreateSources < ActiveRecord::Migration
  def change
    create_table :sources do |t|
      t.string :date
      t.string :source_type
      t.string :title, limit: 512
      t.string :author
      t.string :alt_date
      t.string :whether_mss
      t.string :current_location
      t.string :location_city
      t.string :location_country
      t.string :link, limit: 512
      t.string :electronic_catalog_format
      t.string :electronic_catalog_open_access
      t.boolean :in_manuscript_table
      t.boolean :deleted
      t.datetime :added_on
      t.references :added_by, index: true
      t.datetime :last_modified
      t.references :last_modified_by, index: true
      t.text :comments
      t.string :cataloging_type
      t.string :status
      t.string :hidden
    end
  end
end
