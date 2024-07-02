class CreateManuscriptComments < ActiveRecord::Migration
  def change
    create_table :manuscript_comments do |t|
      t.references :manuscript, index: true
      t.text :comment
      t.datetime :created_at
      t.references :created_by, index: true
      t.datetime :updated_at
      t.references :updated_by, index: true
    end
  end
end
