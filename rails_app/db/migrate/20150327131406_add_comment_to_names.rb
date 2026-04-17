class AddCommentToNames < ActiveRecord::Migration[4.2]
  def change
    add_column :names, :comment, :text
  end
end
