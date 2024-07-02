class AddCommentToNames < ActiveRecord::Migration
  def change
    add_column :names, :comment, :text
  end
end
