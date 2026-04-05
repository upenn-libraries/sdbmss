class AddReasonToRating < ActiveRecord::Migration[4.2]
  def change
    add_column :ratings, :reason, :text
  end
end
