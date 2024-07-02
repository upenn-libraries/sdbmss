class CreateComments < ActiveRecord::Migration
  def change
    drop_table :entry_comments
    drop_table :manuscript_comments

    create_table :comments do |t|
      t.text     :comment
      t.boolean  :public, default: true
      t.boolean  :is_correction, default: false
      t.datetime :created_at
      t.datetime :updated_at
      t.boolean  :reviewed, default: false
      t.datetime :reviewed_at
      t.boolean  :deleted, default: false
    end

    add_reference :comments, :created_by, :index => true
    add_reference :comments, :updated_by, :index => true
    add_reference :comments, :reviewed_by, :index => true

    add_foreign_key :comments, :users, column: :created_by_id
    add_foreign_key :comments, :users, column: :updated_by_id
    add_foreign_key :comments, :users, column: :reviewed_by_id

    create_table :entry_comments do |t|
    end

    add_reference :entry_comments, :entry, :index => true
    add_reference :entry_comments, :comment, :index => true

    add_foreign_key :entry_comments, :entries, column: :entry_id
    add_foreign_key :entry_comments, :comments, column: :comment_id

    create_table :manuscript_comments do |t|
    end

    add_reference :manuscript_comments, :manuscript, :index => true
    add_reference :manuscript_comments, :comment, :index => true

    add_foreign_key :manuscript_comments, :manuscripts, column: :manuscript_id
    add_foreign_key :manuscript_comments, :comments, column: :comment_id
  end
end
