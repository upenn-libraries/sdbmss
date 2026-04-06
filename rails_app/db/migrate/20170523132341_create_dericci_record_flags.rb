class CreateDericciRecordFlags < ActiveRecord::Migration[4.2]
  def change
    create_table :dericci_record_flags do |t|
      t.integer :dericci_record_id
      t.text :reason
      t.integer :created_by_id

      t.timestamps null: false
    end
    remove_column :dericci_records, :flagged
  end
end
