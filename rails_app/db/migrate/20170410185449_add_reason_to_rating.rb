class AddReasonToRating < ActiveRecord::Migration
  def change
    add_column :ratings, :reason, :text
  end
end
