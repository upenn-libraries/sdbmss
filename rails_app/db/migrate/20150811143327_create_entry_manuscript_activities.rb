class CreateEntryManuscriptActivities < ActiveRecord::Migration
  def change
    create_table :entry_manuscript_activities do |t|
      t.references :activity, index: true
      t.integer :entry_id
      t.integer :manuscript_id
    end
    add_foreign_key :entry_manuscript_activities, :activities, column: :activity_id
  end
end
