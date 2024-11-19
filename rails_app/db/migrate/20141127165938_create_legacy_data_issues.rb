class CreateLegacyDataIssues < ActiveRecord::Migration
  def change
    create_table :legacy_data_issues do |t|
      t.string :table_name
      t.integer :record_id
      t.string :issue_type
      t.string :explanation, limit: 1024
    end
  end
end
