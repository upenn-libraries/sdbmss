class RenameSourceCommentColumns < ActiveRecord::Migration
  def change

    drop_table :source_comments

    create_table :source_comments do |t|
    end

    add_reference :source_comments, :source, :index => true
    add_reference :source_comments, :comment, :index => true

    add_foreign_key :source_comments, :sources, column: :source_id
    add_foreign_key :source_comments, :comments, column: :comment_id
  
  end
end
