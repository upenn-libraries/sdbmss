class CreateSourceComments < ActiveRecord::Migration
  def change
    create_table :source_comments do |t|
    end

    add_reference :source_comments, :name, :index => true
    add_reference :source_comments, :comment, :index => true

    add_foreign_key :source_comments, :names, column: :name_id
    add_foreign_key :source_comments, :comments, column: :comment_id

  end
end
