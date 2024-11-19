class CreateNames < ActiveRecord::Migration
  def change
    create_table :names do |t|
      t.string :name
      t.references :entry, index: true
      t.integer :viaf_id
      t.boolean :is_artist, default: false
      t.boolean :is_author, default: false
      t.boolean :is_scribe, default: false
      t.boolean :is_provenance_agent, default: false
      t.boolean :approved
      t.references :approved_by, index: true
      t.datetime :approved_date
      t.datetime :created_at
      t.references :created_by, index: true
      t.datetime :updated_at
      t.references :updated_by, index: true

      t.index :name, unique: true
      t.index :is_artist
      t.index :is_author
      t.index :is_scribe
      t.index :is_provenance_agent
    end
  end
end
