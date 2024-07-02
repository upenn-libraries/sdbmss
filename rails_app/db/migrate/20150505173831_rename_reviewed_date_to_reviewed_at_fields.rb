class RenameReviewedDateToReviewedAtFields < ActiveRecord::Migration
  def change
    remove_column :languages, :reviewed_date
    remove_column :manuscripts, :reviewed_date
    remove_column :names, :reviewed_date
    remove_column :places, :reviewed_date
    remove_column :sources, :reviewed_date

    add_column :languages, :reviewed_at, :datetime
    add_column :manuscripts, :reviewed_at, :datetime
    add_column :names, :reviewed_at, :datetime
    add_column :places, :reviewed_at, :datetime
    add_column :sources, :reviewed_at, :datetime
  end
end
