class CreateNameComments < ActiveRecord::Migration
  def change
    create_table :name_comments do |t|
    end

    add_reference :name_comments, :name, :index => true
    add_reference :name_comments, :comment, :index => true

    add_foreign_key :name_comments, :names, column: :name_id
    add_foreign_key :name_comments, :comments, column: :comment_id

  end
end
